pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as Net
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// qmllint disable unresolved-type
ColumnLayout {
    id: root
    required property Net.Network network
    required property int controlSize
    property bool opened
    property var values: null
    property var pending: null
    property string error
    property string connectionError
    property bool confirming
    property var settings: null
    readonly property Net.WifiNetwork wifi: network as Net.WifiNetwork
    readonly property Net.WiredDevice wired: network?.device as Net.WiredDevice
    readonly property var link: wifi?.connected ? Network.wifiLink : null
    readonly property var profile: network?.nmSettings.find(profile => profile.uuid === values?.["GENERAL.CON-UUID"]?.[0]) ?? network?.nmSettings[0] ?? null // qmllint disable missing-property
    signal joinRequested
    signal shareRequested
    signal forgotten

    spacing: 8
    onNetworkChanged: {
        confirming = false;
        refresh();
    }
    onOpenedChanged: if (opened)
        refresh()
    onProfileChanged: settings = profile?.read() ?? null

    function refresh() {
        values = null;
        error = "";
        pending = null;
        if (!opened || !network?.connected)
            return;
        const request = Network.queryDetails(network.device);
        pending = request;
        request.then(values => {
            if (root.pending !== request)
                return;
            root.values = values;
            root.pending = null;
        }).catch(error => {
            if (root.pending !== request)
                return;
            root.pending = null;
            root.error = "Could not read connection details.";
            console.warn("Network details:", error.message);
        });
        if (wifi !== null)
            Network.refreshWifiLink();
    }

    Connections {
        target: root.network
        function onConnectedChanged() {
            root.refresh();
        }
    }

    Connections {
        target: root.profile
        function onSettingsChanged() {
            root.settings = root.profile.read();
        }
    }

    Icon {
        Layout.alignment: Qt.AlignHCenter
        implicitSize: root.controlSize
        name: Network.iconName(root.network)
        color: Theme.textSecondary
        pulsing: root.network?.stateChanging ?? false
    }

    Text {
        Layout.fillWidth: true
        text: root.network?.name ?? ""
        font.pixelSize: 15
        font.bold: true
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        Button {
            Layout.preferredWidth: root.controlSize
            Layout.preferredHeight: root.controlSize
            variant: Button.Filled
            iconName: root.network?.connected ? "entries-unlinked-symbolic" : "entries-linked-symbolic"
            enabled: root.network !== null && !root.network.stateChanging
            onClicked: root.network.connected ? root.network.disconnect() : root.joinRequested()
            tooltip.text: root.network?.stateChanging ? Net.ConnectionState.toString(root.network.state) + "…" : root.network?.connected ? "Disconnect" : "Connect"
        }

        Button {
            Layout.preferredWidth: root.controlSize
            Layout.preferredHeight: root.controlSize
            variant: Button.Filled
            visible: root.wifi !== null && (Network.usesPassword(root.wifi) || root.wifi.security === Net.WifiSecurityType.Open)
            enabled: root.wifi !== null && !root.wifi.stateChanging && (root.wifi.security === Net.WifiSecurityType.Open || root.profile !== null && (!root.wifi.connected || root.values !== null))
            iconName: "qr-code"
            onClicked: root.shareRequested()
            tooltip.text: "Share network"
        }

        Button {
            Layout.preferredWidth: root.controlSize
            Layout.preferredHeight: root.controlSize
            variant: Button.Filled
            visible: root.network?.known ?? false
            enabled: !root.confirming
            iconName: "user-trash-symbolic"
            palette.buttonText: Theme.critical
            onClicked: root.confirming = true
            tooltip.text: "Forget network"
        }
    }

    WrapperRectangle {
        Layout.fillWidth: true
        visible: root.confirming
        margin: 12
        radius: 8
        color: Qt.alpha(Theme.textPrimary, 0.04)

        ColumnLayout {
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Forget this network and remove its saved settings?"
                color: Theme.textPrimary
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "Cancel"
                    font.pixelSize: 12
                    onClicked: root.confirming = false
                }
                Button {
                    text: "Forget"
                    font.pixelSize: 12
                    palette.buttonText: Theme.critical
                    onClicked: {
                        root.network.forget();
                        root.forgotten();
                    }
                }
            }
        }
    }

    Separator {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    ColumnLayout {
        Layout.leftMargin: 8
        spacing: 0

        TextMetrics {
            id: labelMetrics
            text: "Gateway"
            font.pixelSize: 12
        }

        Repeater {
            model: [["Type", root.wifi ? [root.link?.standard, root.values?.["WIFI.SECURITY"]?.[0] ?? Net.WifiSecurityType.toString(root.wifi.security)].filter(Boolean).join(" · ") : "", root.wifi !== null], ["Link", root.wifi ? [root.link?.band, root.link?.speed > 0 ? root.link.speed + " Mbps" : ""].filter(Boolean).join(" · ") || "—" : root.wired?.linkSpeed > 0 ? root.wired.linkSpeed + " Mbps" : "—"], ["Device", [root.network?.device.name, root.wifi ? Math.round(root.wifi.signalStrength * 100) + "%" : ""].filter(Boolean).join(" · ") || "—"], ["IPv4", root.values?.["IP4.ADDRESS"]?.join(", ") ?? "—"], ["Gateway", root.values?.["IP4.GATEWAY"]?.join(", ") ?? "—"], ["DNS", root.values?.["IP4.DNS"]?.join(", ") ?? "—"], ["IPv6", root.values?.["IP6.ADDRESS"]?.join(", ") ?? "—"], ["MAC", root.network?.device.address ?? "—"]]

            delegate: ColumnLayout {
                id: row
                required property var modelData
                visible: modelData[2] !== false
                spacing: 0

                Separator {
                    visible: row.modelData[0] === "IPv4"
                    Layout.leftMargin: -8
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                RowLayout {
                    spacing: 8

                    Text {
                        Layout.minimumWidth: Math.ceil(Math.max(labelMetrics.advanceWidth, labelMetrics.boundingRect.width))
                        text: row.modelData[0]
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }

                    CopyButton {
                        text: row.modelData[1]
                        enabled: text !== "—"
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        visible: root.pending !== null || root.error !== "" || root.connectionError !== ""
        text: root.connectionError || root.error || "Loading…"
        font.pixelSize: 12
        color: root.connectionError || root.error ? Theme.warning : Theme.textSecondary
        wrapMode: Text.Wrap
    }

    Separator {
        visible: root.profile !== null
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    Switch {
        Layout.fillWidth: true
        visible: root.profile !== null
        horizontalPadding: 8
        text: "Auto join"
        font.pixelSize: 12
        checked: root.settings?.connection?.autoconnect ?? true
        onToggled: root.profile.write({
            connection: {
                autoconnect: checked
            }
        })
    }
}
