#!/usr/bin/env python3
"""Pair one BlueZ device, forwarding agent requests as JSON lines over stdio."""

import json
import os
import signal
import sys

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLibUnix", "2.0")
from gi.repository import Gio, GLib, GLibUnix


AGENT_PATH = "/org/quickshell/BluetoothAgent"
AGENT_XML = """
<node><interface name="org.bluez.Agent1">
  <method name="Release"/>
  <method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
  <method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
  <method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
  <method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
  <method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
  <method name="RequestAuthorization"><arg type="o" direction="in"/></method>
  <method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
  <method name="Cancel"/>
</interface></node>
"""


def emit(event, **values):
    try:
        os.write(sys.stdout.fileno(), (json.dumps({"event": event, **values}) + "\n").encode())
    except BrokenPipeError:
        pass


class Pairing:
    def __init__(self, device):
        self.device = device
        self.loop = GLib.MainLoop()
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
        self.owner = self.bus.call_sync(
            "org.freedesktop.DBus", "/org/freedesktop/DBus",
            "org.freedesktop.DBus", "GetNameOwner",
            GLib.Variant("(s)", ("org.bluez",)), None,
            Gio.DBusCallFlags.NONE, 5000, None,
        ).unpack()[0]
        self.registered = False
        self.done = False
        self.cancelling = False
        self.pending = None
        self.serial = 0
        self.buffer = b""
        info = Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0]
        self.bus.register_object(AGENT_PATH, info, self.agent_call, None, None)
        self.bus.connect("closed", lambda *_: self.finish("error", "Bluetooth service disconnected"))
        os.set_blocking(sys.stdin.fileno(), False)
        GLib.io_add_watch(sys.stdin.fileno(), GLib.IOCondition.IN | GLib.IOCondition.HUP, self.read)
        GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, self.cancel)

    def call(self, path, interface, method, parameters=None, callback=None, timeout=10000):
        self.bus.call("org.bluez", path, interface, method, parameters, None,
                      Gio.DBusCallFlags.NONE, timeout, None, callback)

    def start(self):
        self.call("/org/bluez", "org.bluez.AgentManager1", "RegisterAgent",
                  GLib.Variant("(os)", (AGENT_PATH, "KeyboardDisplay")), self.agent_registered)
        self.loop.run()

    def agent_registered(self, bus, result):
        try:
            bus.call_finish(result)
        except GLib.Error as error:
            self.fail(error)
            return
        self.registered = True
        if self.cancelling:
            self.finish("cancelled")
            return
        emit("started")
        self.call(self.device, "org.bluez.Device1", "Pair", callback=self.paired, timeout=180000)

    def paired(self, bus, result):
        try:
            bus.call_finish(result)
        except GLib.Error as error:
            if self.cancelling:
                self.finish("cancelled")
            else:
                self.fail(error)
            return
        self.finish("paired")

    def fail(self, error):
        name = Gio.DBusError.get_remote_error(error) or ""
        self.finish("error", error.message.removeprefix(f"GDBus.Error:{name}: "), name)

    def reject_pending(self):
        if self.pending is not None:
            _, _, invocation = self.pending
            self.pending = None
            invocation.return_dbus_error("org.bluez.Error.Canceled", "Pairing cancelled")

    def agent_call(self, bus, sender, path, interface, method, parameters, invocation):
        args = parameters.unpack()
        if sender != self.owner or (args and args[0] != self.device):
            invocation.return_dbus_error("org.bluez.Error.Rejected", "Unexpected pairing request")
            return
        if method in ("Cancel", "Release"):
            self.reject_pending()
            emit("clear")
            invocation.return_value(None)
            if method == "Release":
                self.registered = False
                self.finish("error", "Bluetooth pairing agent was released")
            return
        if self.cancelling or self.done:
            invocation.return_dbus_error("org.bluez.Error.Canceled", "Pairing cancelled")
            return
        if method in ("DisplayPinCode", "DisplayPasskey"):
            emit("prompt", kind="display", code=str(args[1]).zfill(6),
                 entered=args[2] if method == "DisplayPasskey" else 0)
            invocation.return_value(None)
            return
        if self.pending is not None:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "Another request is pending")
            return
        kinds = {"RequestPinCode": "pin", "RequestPasskey": "passkey",
                 "RequestConfirmation": "confirm", "RequestAuthorization": "authorize",
                 "AuthorizeService": "service"}
        self.serial += 1
        self.pending = (self.serial, method, invocation)
        prompt = {"id": self.serial, "kind": kinds[method]}
        if method == "RequestConfirmation":
            prompt["code"] = str(args[1]).zfill(6)
        elif method == "AuthorizeService":
            prompt["uuid"] = args[1]
        emit("prompt", **prompt)

    def read(self, fd, condition):
        chunk = os.read(fd, 4096)
        if not chunk:
            self.cancel()
            return False
        self.buffer += chunk
        while b"\n" in self.buffer:
            line, self.buffer = self.buffer.split(b"\n", 1)
            try:
                message = json.loads(line)
                if message["action"] == "cancel":
                    self.cancel()
                elif message["action"] == "reply":
                    self.reply(message)
            except (ValueError, KeyError, TypeError) as error:
                print(f"Invalid pairing response: {error}", file=sys.stderr, flush=True)
        return not self.done

    def reply(self, message):
        if self.pending is None or message["id"] != self.pending[0]:
            return
        _, method, invocation = self.pending
        value = message.get("value")
        if method == "RequestPinCode":
            if not isinstance(value, str) or not 1 <= len(value) <= 16 or not value.isascii() or not value.isalnum():
                raise ValueError("PIN must contain 1–16 letters or digits")
            response = GLib.Variant("(s)", (value,))
        elif method == "RequestPasskey":
            if type(value) is not int or not 0 <= value <= 999999:
                raise ValueError("Passkey must contain up to six digits")
            response = GLib.Variant("(u)", (value,))
        elif value is True:
            response = None
        else:
            self.pending = None
            invocation.return_dbus_error("org.bluez.Error.Rejected", "Pairing rejected")
            return
        self.pending = None
        invocation.return_value(response)
        emit("clear")

    def cancel(self):
        if self.done or self.cancelling:
            return False
        self.cancelling = True
        self.reject_pending()
        if self.registered:
            self.call(self.device, "org.bluez.Device1", "CancelPairing", callback=self.cancelled, timeout=5000)
        return False

    def cancelled(self, bus, result):
        try:
            bus.call_finish(result)
        except GLib.Error as error:
            if not self.done:
                self.fail(error)
            return
        self.finish("cancelled")

    def finish(self, status, message="", name=""):
        if self.done:
            return
        self.done = True
        self.reject_pending()
        if self.registered and not self.bus.is_closed():
            try:
                self.bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", "UnregisterAgent",
                                   GLib.Variant("(o)", (AGENT_PATH,)), None, Gio.DBusCallFlags.NONE, 1000, None)
            except GLib.Error:
                pass
        emit("result", status=status, message=message, name=name)
        self.loop.quit()


if __name__ == "__main__":
    try:
        Pairing(sys.argv[1]).start()
    except (GLib.Error, IndexError) as error:
        emit("result", status="error", message=str(error), name="")
        sys.exit(1)
