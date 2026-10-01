pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.components.bar
import qs.config

// qmllint disable unresolved-type
Button {
    id: root
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool connected: root.adapter?.devices.values.some(device => device.connected) ?? false
    visible: root.adapter !== null
    onClicked: popup.visible = !popup.visible
    content: Icon {
        implicitSize: 18
        source: {
            if (!root.adapter?.enabled)
                return Quickshell.iconPath("bluetooth-disabled-symbolic");
            return Quickshell.iconPath(root.connected ? "bluetooth-active-symbolic" : "bluetooth-symbolic");
        }
    }
    Popup {
        id: popup
        anchorItem: root
        ColumnLayout {
            spacing: 8
            Controls.Switch {
                text: "Bluetooth"
                checked: root.adapter?.enabled ?? false
                enabled: root.adapter !== null && (root.adapter.state === BluetoothAdapterState.Enabled || root.adapter.state === BluetoothAdapterState.Disabled)
                onToggled: root.adapter.enabled = checked
            }
            Repeater {
                id: deviceList
                model: root.adapter?.devices.values.filter(device => device.paired || device.connected) ?? []
                delegate: RowLayout {
                    id: deviceRow
                    required property BluetoothDevice modelData
                    readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

                    spacing: 8
                    Text {
                        color: Theme.textPrimary
                        text: deviceRow.modelData.name || deviceRow.modelData.address
                    }
                    Text {
                        color: Theme.textPrimary
                        text: BluetoothDeviceState.toString(deviceRow.modelData.state)
                    }
                    Text {
                        color: Theme.textPrimary
                        visible: deviceRow.modelData.batteryAvailable
                        text: Math.round(deviceRow.modelData.battery * 100) + "%"
                    }
                    Controls.Button {
                        text: deviceRow.modelData.connected ? "Disconnect" : "Connect"
                        enabled: root.adapter?.state === BluetoothAdapterState.Enabled && !deviceRow.busy && !deviceRow.modelData.blocked
                        onClicked: {
                            if (deviceRow.modelData.connected)
                                deviceRow.modelData.disconnect();
                            else
                                deviceRow.modelData.connect();
                        }
                    }
                }
            }
            Text {
                color: Theme.textPrimary
                visible: deviceList.count === 0
                text: "No paired devices"
            }
        }
    }
}
