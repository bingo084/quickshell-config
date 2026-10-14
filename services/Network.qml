pragma Singleton

import QtQml
import Quickshell
import Quickshell.Networking

Singleton {
    id: root
    readonly property WiredDevice wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected) ?? null // qmllint disable missing-property
    readonly property NetworkDevice wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected) ?? null // qmllint disable missing-property
    readonly property WifiNetwork wifiNetwork: wifi?.networks.values.find(network => network.connected) ?? null // qmllint disable missing-property
    readonly property NetworkDevice device: wired ?? wifi
    readonly property Network network: device?.networks.values.find(network => network.connected) ?? null // qmllint disable missing-property
    readonly property bool online: device !== null && (!Networking.connectivityCheckEnabled || Networking.connectivity === NetworkConnectivity.Full)
    property real wifiLink: -1
    property var wifiRequest: null
    property var details: null
    property var request: null
    readonly property bool detailsLoading: request !== null
    signal ready

    onOnlineChanged: {
        if (online)
            refreshDelay.restart();
        else
            refreshDelay.stop();
    }
    onDeviceChanged: {
        details = null;
        refreshDetails();
    }
    onNetworkChanged: {
        details = null;
        refreshDetails();
    }
    onWifiNetworkChanged: {
        wifiLink = -1;
        refreshWifiLink();
    }

    function refreshDetails() {
        if (!root.device || !root.network) {
            root.request = null;
            return;
        }
        const request = Command.run(["env", "LC_ALL=C", "nmcli", "--terse", "--escape", "no", "--fields", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", root.device.name]);
        root.request = request;
        return request.then(result => {
            if (root.request !== request)
                return;
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            root.details = root.parseDetails(result.stdout);
            root.request = null;
        }).catch(error => {
            if (root.request !== request)
                return;
            root.details = null;
            root.request = null;
            console.warn("network details query failed:", error.message);
        });
    }

    function refreshWifiLink() {
        if (!root.wifiNetwork) {
            root.wifiRequest = null;
            return;
        }
        const request = Command.run(["busctl", "--system", "--json=short", "call", "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager", "org.freedesktop.NetworkManager", "GetDeviceByIpIface", "s", root.wifi.name]).then(result => {
            if (result.exitCode !== 0)
                throw new Error(result.stderr.trim());
            const path = JSON.parse(result.stdout).data[0];
            return Command.run(["busctl", "--system", "--json=short", "get-property", "org.freedesktop.NetworkManager", path, "org.freedesktop.NetworkManager.Device.Wireless", "Bitrate"]);
        });
        root.wifiRequest = request;
        return request.then(result => {
            if (root.wifiRequest !== request)
                return;
            if (result.exitCode !== 0)
                throw new Error(result.stderr.trim());
            root.wifiLink = JSON.parse(result.stdout).data / 1000;
            root.wifiRequest = null;
        }).catch(error => {
            if (root.wifiRequest !== request)
                return;
            root.wifiLink = -1;
            root.wifiRequest = null;
            console.warn("Wi-Fi link query failed:", error.message);
        });
    }

    function parseDetails(text: string): var {
        const result = {};
        for (const line of text.split("\n")) {
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const key = line.slice(0, colon).replace(/\[\d+\]$/, "");
            const value = line.slice(colon + 1).trim();
            if (value === "")
                continue;
            if (!result[key])
                result[key] = [];
            result[key].push(value);
        }
        return result;
    }

    Timer {
        id: refreshDelay
        interval: 2000
        onTriggered: root.ready()
    }
}
