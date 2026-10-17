pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.components.bar
import qs.widgets.bluetooth

Button {
    id: root
    visible: BluetoothPopup.adapter !== null
    onClicked: BluetoothPopup.toggle(root)

    content: Icon {
        name: {
            if (BluetoothPopup.adapter?.state === BluetoothAdapterState.Blocked) // qmllint disable unresolved-type
                return "bluetooth-hardware-disabled-symbolic";
            if (!BluetoothPopup.adapter?.enabled)
                return "bluetooth-disabled-symbolic";
            if (BluetoothPopup.pairing || BluetoothPopup.devices.some(device => device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting))
                return "bluetooth-acquiring-symbolic";
            return BluetoothPopup.devices.some(device => device.connected) ? "bluetooth-active-symbolic" : "bluetooth-symbolic";
        }
    }
}
