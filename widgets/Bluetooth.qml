pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.components.bar as Bar
import qs.config
import qs.widgets.bluetooth

// qmllint disable unresolved-type
Bar.Button {
    id: root
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values.filter(device => device.paired || device.connected).sort((a, b) => Number(b.connected) - Number(a.connected)) ?? [] // qmllint disable missing-property
    property BluetoothDevice selected: null

    visible: adapter !== null
    onClicked: popup.toggle()
    onAdapterChanged: selected = null
    onDevicesChanged: {
        if (selected !== null && !devices.includes(selected))
            selected = null;
    }

    content: Icon {
        name: {
            if (root.adapter?.state === BluetoothAdapterState.Blocked)
                return "bluetooth-hardware-disabled-symbolic";
            if (!root.adapter?.enabled)
                return "bluetooth-disabled-symbolic";
            if (root.devices.some(device => device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting))
                return "bluetooth-acquiring-symbolic";
            return root.devices.some(device => device.connected) ? "bluetooth-active-symbolic" : "bluetooth-symbolic";
        }
    }

    Bar.Popup {
        id: popup
        anchorItem: root
        contentWidth: 316
        contentMargin: 13
        focusable: true
        onVisibleChanged: {
            if (visible)
                root.selected = null;
        }

        ColumnLayout {
            spacing: 12

            ColumnLayout {
                Layout.leftMargin: 6
                visible: root.selected === null
                spacing: 12

                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Switch {
                        checked: root.adapter?.enabled ?? false
                        enabled: root.adapter !== null && (root.adapter.state === BluetoothAdapterState.Enabled || root.adapter.state === BluetoothAdapterState.Disabled)
                        onToggled: root.adapter.enabled = checked
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.adapter?.state !== BluetoothAdapterState.Enabled || root.devices.length === 0
                    color: root.adapter?.state === BluetoothAdapterState.Blocked ? Theme.warning : Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    text: {
                        if (root.adapter === null)
                            return "No Bluetooth adapter";
                        switch (root.adapter.state) {
                        case BluetoothAdapterState.Disabled:
                            return "Bluetooth is off";
                        case BluetoothAdapterState.Enabling:
                            return "Turning on…";
                        case BluetoothAdapterState.Disabling:
                            return "Turning off…";
                        case BluetoothAdapterState.Blocked:
                            return "Bluetooth is blocked";
                        default:
                            return "No paired devices";
                        }
                    }
                }
            }

            RowLayout {
                visible: root.selected !== null

                Button {
                    Layout.alignment: Qt.AlignBaseline
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    font: title.font
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    onClicked: root.selected = null
                }

                Text {
                    id: title
                    Layout.alignment: Qt.AlignBaseline
                    text: "Device details"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                }
            }

            ListView {
                id: deviceList
                Layout.fillWidth: true
                visible: root.selected === null && root.adapter?.state === BluetoothAdapterState.Enabled && root.devices.length > 0
                implicitHeight: Math.min(contentHeight, 310)
                clip: true
                spacing: 4
                model: root.devices
                Controls.ScrollBar.vertical: Controls.ScrollBar {}

                delegate: DeviceRow {
                    required property BluetoothDevice modelData
                    width: deviceList.width
                    device: modelData
                    onDetailsRequested: root.selected = modelData
                }
            }

            Flickable {
                Layout.fillWidth: true
                visible: root.selected !== null
                implicitHeight: Math.min(details.implicitHeight, 460)
                contentHeight: details.implicitHeight
                clip: true
                Controls.ScrollBar.vertical: Controls.ScrollBar {}

                Loader {
                    id: details
                    width: parent.width
                    active: root.selected !== null
                    sourceComponent: DeviceDetails {
                        device: root.selected
                        onBackRequested: root.selected = null
                    }
                }
            }
        }
    }
}
