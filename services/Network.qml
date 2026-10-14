pragma Singleton

import QtQml
import Quickshell
import Quickshell.Networking

Singleton {
    id: root
    readonly property NetworkDevice wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected) ?? null // qmllint disable missing-property
    readonly property NetworkDevice wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected) ?? null // qmllint disable missing-property
    readonly property NetworkDevice device: wired ?? wifi
    readonly property Network network: device?.networks.values.find(network => network.connected) ?? null // qmllint disable missing-property
    readonly property bool online: device !== null && (!Networking.connectivityCheckEnabled || Networking.connectivity === NetworkConnectivity.Full)
    property var details: null
    property int detailsRevision
    property bool detailsLoading
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

    function refreshDetails() {
        detailsRevision++;
        if (detailsLoading || !root.device || !root.network)
            return;
        const revision = detailsRevision;
        detailsLoading = true;
        return Command.run(["env", "LC_ALL=C", "nmcli", "--terse", "--escape", "no", "--fields", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", root.device.name]).then(result => {
            if (revision !== root.detailsRevision)
                return;
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            root.details = root.parseDetails(result.stdout);
        }).catch(error => {
            if (revision !== root.detailsRevision)
                return;
            root.details = null;
            console.warn("network details query failed:", error.message);
        }).then(() => {
            root.detailsLoading = false;
            if (revision !== root.detailsRevision)
                Qt.callLater(root.refreshDetails);
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
