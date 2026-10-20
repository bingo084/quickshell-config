pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as Net
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// qmllint disable unresolved-type
WrapperRectangle {
    id: root
    required property Net.WifiNetwork network
    required property int controlSize
    property bool joining
    signal chosen
    signal detailsRequested
    signal cancelRequested

    radius: 7
    color: body.down ? Theme.pressedBackground : body.hovered ? Theme.hoveredBackground : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        spacing: 4

        Button {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 6
            background: null
            enabled: root.network !== null && !root.joining && !root.network.stateChanging
            opacity: enabled || root.joining ? 1 : 0.5
            onClicked: root.network.connected ? root.detailsRequested() : root.chosen()

            contentItem: RowLayout {
                spacing: 8

                Icon {
                    size: root.controlSize
                    name: Network.iconName(root.network)
                    pulsing: root.joining || (root.network?.stateChanging ?? false)
                    color: Theme.textSecondary
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        id: nameLabel
                        Layout.fillWidth: true
                        text: root.network?.name ?? ""
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        elide: Text.ElideRight

                        Tooltip {
                            anchorItem: nameLabel
                            enabled: nameLabel.truncated
                            text: nameLabel.text
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.joining ? "Connecting…" : root.network?.stateChanging ? Net.ConnectionState.toString(root.network.state) + "…" : root.network?.connected ? "Connected" : root.network?.known ? "Saved" : ""
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }

                Icon {
                    visible: root.network !== null && !root.network.connected && !root.joining && ![Net.WifiSecurityType.Open, Net.WifiSecurityType.Owe].includes(root.network.security)
                    name: "system-lock-screen-symbolic"
                    implicitSize: 16
                    size: root.controlSize
                    color: Theme.textTertiary
                }
            }
        }

        Button {
            visible: (root.network?.connected ?? false) || root.joining
            size: root.controlSize
            Layout.rightMargin: body.padding
            radius: height / 2
            iconName: root.joining ? "window-close-symbolic" : "preferences-system-symbolic"
            icon.color: hovered ? Theme.textPrimary : Theme.textSecondary
            onClicked: root.joining ? root.cancelRequested() : root.detailsRequested()

            tooltip.text: root.joining ? "Cancel connection" : "Network details"
        }
    }
}
