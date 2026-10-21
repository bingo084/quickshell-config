pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.widgets.bluetooth

BarButton {
    id: root
    visible: BluetoothPopup.adapter !== null
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            BluetoothPopup.toggle(root);
        } else {
            PopupHost.close();
            Quickshell.execDetached(["blueman-manager"]);
        }
    }

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
