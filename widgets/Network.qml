import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as Net
import qs.components
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    readonly property Net.WifiNetwork wifiNetwork: Network.network as Net.WifiNetwork

    onClicked: popup.toggle()

    content: Icon {
        source: {
            if (Network.wired)
                return Quickshell.iconPath("network-wired-symbolic");
            if (root.wifiNetwork) {
                const strength = root.wifiNetwork.signalStrength;
                const level = strength < 0.25 ? "weak" : strength < 0.5 ? "ok" : strength < 0.75 ? "good" : "excellent";
                return Quickshell.iconPath(`network-wireless-signal-${level}-symbolic`);
            }
            return Quickshell.iconPath("network-wireless-disconnected-symbolic");
        }
    }

    Popup {
        id: popup
        anchorItem: root
        onVisibleChanged: if (visible)
            Network.refreshDetails()
        ColumnLayout {
            spacing: 6
            Text {
                color: Theme.textPrimary
                text: Network.network?.name || (Network.device ? qsTr("Connected") : qsTr("Disconnected"))
            }
            Text {
                color: Theme.textPrimary
                text: "Device: " + (Network.device?.name ?? "-")
            }
            Text {
                color: Theme.textPrimary
                text: "MAC: " + (Network.device?.address ?? "-")
            }
            Text {
                color: Theme.textPrimary
                visible: root.wifiNetwork !== null
                text: "Signal: " + Math.round((root.wifiNetwork?.signalStrength ?? 0) * 100) + "%"
            }

            Repeater {
                model: [
                    {
                        label: "IPv4",
                        key: "IP4.ADDRESS"
                    },
                    {
                        label: "Gateway",
                        key: "IP4.GATEWAY"
                    },
                    {
                        label: "DNS",
                        key: "IP4.DNS"
                    },
                    {
                        label: "IPv6",
                        key: "IP6.ADDRESS"
                    }
                ]

                delegate: Text {
                    required property var modelData

                    color: Theme.textPrimary
                    text: {
                        let value = "—";
                        if (Network.details !== null)
                            value = Network.details[modelData.key]?.join(", ") ?? "—";
                        else if (Network.detailsLoading)
                            value = "Loading…";
                        return modelData.label + ": " + value;
                    }
                }
            }
        }
    }
}
