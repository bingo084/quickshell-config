pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.config

// qmllint disable unresolved-type
ColumnLayout {
    id: root
    required property BluetoothAdapter adapter
    required property int controlSize
    property bool scanning
    readonly property var devices: adapter?.devices.values.filter(device => !device.paired && !device.connected) ?? [] // qmllint disable missing-property
    signal pairRequested(device: BluetoothDevice)

    spacing: 10

    ListView {
        id: deviceList
        Layout.fillWidth: true
        visible: root.adapter?.state === BluetoothAdapterState.Enabled && count > 0
        implicitHeight: Math.min(contentHeight, 310)
        clip: true
        spacing: 4
        model: root.devices
        Controls.ScrollBar.vertical: Controls.ScrollBar {}

        delegate: Button {
            id: entry
            required property BluetoothDevice modelData
            width: deviceList.width
            onClicked: root.pairRequested(modelData)

            contentItem: RowLayout {
                spacing: 8

                Icon {
                    padding: (root.controlSize - implicitSize) / 2
                    name: (entry.modelData?.icon || "bluetooth") + "-symbolic"
                    color: Theme.textSecondary
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        id: nameLabel
                        Layout.fillWidth: true
                        text: entry.modelData?.name || entry.modelData?.address || ""
                        font.pixelSize: 13
                        color: Theme.textPrimary
                        elide: Text.ElideRight

                        Tooltip {
                            anchorItem: nameLabel
                            enabled: nameLabel.truncated
                            text: nameLabel.text
                        }
                    }

                    Text {
                        visible: !!entry.modelData?.name
                        text: entry.modelData?.address ?? ""
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        visible: root.adapter?.state !== BluetoothAdapterState.Enabled || root.devices.length === 0
        text: {
            if (root.adapter?.state === BluetoothAdapterState.Blocked)
                return "Bluetooth is blocked";
            if (root.adapter?.state !== BluetoothAdapterState.Enabled)
                return "Bluetooth is off";
            return "Make your device discoverable.";
        }
        font.pixelSize: 12
        color: root.adapter?.state === BluetoothAdapterState.Blocked ? Theme.warning : Theme.textSecondary
        wrapMode: Text.Wrap
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        Layout.margins: 4
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: root.scanning
        implicitHeight: 2
        radius: 1
        color: Qt.alpha(Theme.textSecondary, 0.1)
        clip: true

        Rectangle {
            id: light
            width: track.width * 0.24
            height: track.height
            radius: 1
            color: Qt.alpha(Theme.textSecondary, 0.65)

            NumberAnimation on x {
                from: -light.width
                to: track.width
                duration: 1600
                loops: Animation.Infinite
                running: root.scanning && from < 0 && to > 0
            }
        }
    }
}
