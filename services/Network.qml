pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root
    readonly property NetworkDevice wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected) ?? null
    readonly property NetworkDevice wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected) ?? null
    readonly property NetworkDevice device: wired ?? wifi
    readonly property Network network: device?.networks.values.find(network => network.connected) ?? null
    readonly property bool online: device !== null && (!Networking.connectivityCheckEnabled || Networking.connectivity === NetworkConnectivity.Full)
    property var details: null
    property int detailsRevision
    readonly property bool detailsLoading: detailQuery.running
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
        if (detailQuery.running || !root.device || !root.network)
            return;
        detailQuery.revision = detailsRevision;
        detailQuery.running = true;
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

    Process {
        id: detailQuery
        property int revision

        // qmllint disable incompatible-type
        environment: ({
                LC_ALL: "C"
            })
        // qmllint enable incompatible-type
        command: ["nmcli", "--terse", "--escape", "no", "--fields", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", root.device?.name ?? ""]
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (detailQuery.revision !== root.detailsRevision) {
                Qt.callLater(root.refreshDetails);
                return;
            }
            if (exitCode !== 0) {
                root.details = null;
                console.warn("network details query failed (exit " + exitCode + "):", stderr.text.trim());
                return;
            }
            root.details = root.parseDetails(stdout.text);
        }
        // qmllint enable signal-handler-parameters
    }

    Timer {
        id: refreshDelay
        interval: 2000
        onTriggered: root.ready()
    }
}
