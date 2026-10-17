pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.components
import qs.config

ColumnLayout {
    id: root
    required property BluetoothDevice device
    required property int controlSize
    property bool opened
    property var prompt: null
    property string error
    property bool cancelling
    readonly property bool busy: query.running
    signal paired
    signal cancelled

    spacing: 10
    Component.onCompleted: start()
    onOpenedChanged: focusInput()
    onDeviceChanged: {
        if (device === null)
            cancel();
    }
    onPromptChanged: {
        input.text = "";
        focusInput();
    }

    function focusInput() {
        Qt.callLater(() => {
            if (root.opened && input.visible)
                input.forceActiveFocus();
        });
    }

    function start() {
        if (device === null)
            return;
        error = "";
        prompt = null;
        cancelling = false;
        query.completed = false;
        query.running = true;
    }

    function cancel() {
        if (!busy) {
            cancelled();
            return;
        }
        cancelling = true;
        query.write(JSON.stringify({
            action: "cancel"
        }) + "\n");
    }

    function reply() {
        const value = prompt.kind === "pin" ? input.text : prompt.kind === "passkey" ? Number(input.text) : true;
        query.write(JSON.stringify({
            action: "reply",
            id: prompt.id,
            value
        }) + "\n");
        prompt = null;
    }

    function receive(message: var) {
        switch (message.event) {
        case "prompt":
            prompt = message;
            break;
        case "clear":
            prompt = null;
            break;
        case "result":
            query.completed = true;
            prompt = null;
            cancelling = false;
            if (message.status === "paired")
                paired();
            else if (message.status === "cancelled")
                cancelled();
            else
                error = message.message;
            break;
        }
    }

    Process {
        id: query
        property bool completed
        command: ["python3", Quickshell.shellPath("scripts/bluetooth-pair.py"), root.device?.dbusPath ?? ""]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.receive(JSON.parse(line))
        }
        stderr: SplitParser {
            onRead: line => console.warn("Bluetooth pairing:", line)
        }
        onRunningChanged: {
            if (!running)
                Qt.callLater(() => {
                    if (!query.running && !query.completed) {
                        root.prompt = null;
                        root.cancelling = false;
                        root.error = "Pairing process could not complete. Please try again.";
                    }
                });
        }
    }

    Icon {
        Layout.alignment: Qt.AlignHCenter
        implicitSize: root.controlSize
        name: (root.device?.icon || "bluetooth") + "-symbolic"
        color: Theme.textSecondary
        pulsing: root.busy
    }

    Text {
        Layout.fillWidth: true
        text: root.device?.name || root.device?.address || ""
        font.pixelSize: 15
        font.bold: true
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Text {
        Layout.fillWidth: true
        font.pixelSize: 12
        color: Theme.textSecondary
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: {
            if (root.error !== "")
                return "Pairing failed";
            if (root.cancelling)
                return "Cancelling…";
            switch (root.prompt?.kind) {
            case "pin":
                return "Enter the device’s PIN.";
            case "passkey":
                return "Enter the passkey.";
            case "confirm":
                return "Does the code match?";
            case "display":
                return "Type this code on the device, then press Enter.";
            case "authorize":
                return "Allow pairing with this device?";
            case "service":
                return "Allow this device to connect?";
            default:
                return "Pairing…";
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.prompt?.code !== undefined
        text: root.prompt?.code ?? ""
        font.pixelSize: 24
        font.letterSpacing: 4
        color: Theme.textPrimary
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.prompt?.kind === "display" && root.prompt.entered > 0
        text: (root.prompt?.entered ?? 0) + " / 6 digits entered"
        font.pixelSize: 11
        color: Theme.textSecondary
    }

    Controls.TextField {
        id: input
        Layout.fillWidth: true
        visible: root.prompt?.kind === "pin" || root.prompt?.kind === "passkey"
        enabled: !root.cancelling
        maximumLength: root.prompt?.kind === "pin" ? 16 : 6
        font.pixelSize: 15
        color: Theme.textPrimary
        horizontalAlignment: TextInput.AlignHCenter
        validator: RegularExpressionValidator {
            regularExpression: root.prompt?.kind === "pin" ? /[A-Za-z0-9]{1,16}/ : /[0-9]{1,6}/
        }
        onAccepted: if (acceptableInput)
            root.reply()
        background: Rectangle {
            radius: 5
            color: Theme.controlBackground
            border.color: input.activeFocus ? Theme.accent : Theme.popupBorder
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.error !== ""
        text: root.error
        font.pixelSize: 12
        color: Theme.warning
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter

        Button {
            text: root.busy ? "Cancel" : "Back"
            enabled: !root.cancelling
            onClicked: root.cancel()
        }

        Button {
            visible: root.prompt?.id !== undefined || root.error !== ""
            enabled: !root.cancelling && (root.error !== "" ? !root.busy : !input.visible || input.acceptableInput)
            variant: Button.Filled
            text: root.error !== "" ? "Retry" : root.prompt?.kind === "confirm" ? "Confirm" : root.prompt?.kind === "authorize" || root.prompt?.kind === "service" ? "Allow" : "Pair"
            onClicked: root.error !== "" ? root.start() : root.reply()
        }
    }
}
