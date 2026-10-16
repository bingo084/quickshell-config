pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.components
import qs.config

// qmllint disable unresolved-type
WrapperRectangle {
    id: root
    required property BluetoothDevice device
    required property int controlSize
    property int padding: 6
    readonly property bool busy: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
    signal detailsRequested

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
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            padding: root.padding
            background: null
            opacity: enabled || root.busy ? 1 : 0.5
            enabled: root.device.adapter?.state === BluetoothAdapterState.Enabled && !root.device.blocked && !root.busy
            onClicked: root.device.connected ? root.device.disconnect() : root.device.connect()

            contentItem: RowLayout {
                spacing: 8

                Icon {
                    padding: (root.controlSize - implicitSize) / 2
                    name: (root.device.icon || "bluetooth") + "-symbolic"
                    pulsing: root.busy
                    color: Theme.textSecondary
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        id: nameLabel
                        Layout.fillWidth: true
                        text: root.device.name || root.device.address
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
                        id: statusLabel
                        Layout.fillWidth: true
                        text: (root.device.blocked ? "Blocked" : BluetoothDeviceState.toString(root.device.state)) + (root.device.batteryAvailable ? " · " + Math.round(root.device.battery * 100) + "%" : "")
                        color: root.device.blocked ? Theme.warning : Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight

                        Tooltip {
                            anchorItem: statusLabel
                            enabled: statusLabel.truncated
                            text: statusLabel.text
                        }
                    }
                }
            }
        }

        Button {
            Layout.preferredWidth: root.controlSize
            Layout.preferredHeight: root.controlSize
            Layout.rightMargin: root.padding
            radius: height / 2
            iconName: "preferences-system-symbolic"
            icon.color: hovered ? Theme.textPrimary : Theme.textSecondary
            onClicked: root.detailsRequested()
        }
    }
}
