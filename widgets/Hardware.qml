import QtQuick
import QtQuick.Layouts
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    onClicked: popup.visible = !popup.visible
    content: RowLayout {
        spacing: 8
        Text {
            color: Theme.textPrimary
            text: "CPU " + (Hardware.cpuValid ? Math.round(Hardware.cpuUsage * 100) + "%" : "—")
        }
        Text {
            color: Theme.textPrimary
            text: "RAM " + (Hardware.memoryValid ? Math.round(Hardware.memoryUsage * 100) + "%" : "—")
        }
    }
    Popup {
        id: popup
        anchorItem: root
        ColumnLayout {
            Text {
                color: Theme.textPrimary
                text: Hardware.cpuValid ? "CPU: " + Math.round(Hardware.cpuUsage * 100) + "%" : "CPU: —"
            }
            Text {
                color: Theme.textPrimary
                text: Hardware.memoryValid ? "RAM: " + (Hardware.memoryUsed / 1024 ** 3).toFixed(1) + " / " + (Hardware.memoryTotal / 1024 ** 3).toFixed(1) + " GiB" : "RAM: —"
            }
        }
    }
}
