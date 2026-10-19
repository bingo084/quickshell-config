import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components.bar
import qs.config
import qs.widgets.battery

Button {
    id: root
    onClicked: popup.toggle()

    content: RowLayout {
        spacing: 4
        BatteryIcon {
            device: UPower.displayDevice
        }
        Text {
            color: Theme.textPrimary
            text: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "--%"
        }
    }

    BatteryPopup {
        id: popup
        anchorItem: root
    }
}
