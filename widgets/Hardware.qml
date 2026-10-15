import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.services
import qs.widgets.hardware

Button {
    id: root

    onClicked: popup.toggle()

    content: RowLayout {
        spacing: 6
        Icon {
            name: "computer-chip-symbolic"
        }

        ColumnLayout {
            spacing: 2

            Repeater {
                model: [
                    {
                        value: Hardware.cpuUsage,
                        valid: Hardware.cpuValid,
                        level: Hardware.cpuLevel
                    },
                    {
                        value: Hardware.memoryUsage,
                        valid: Hardware.memoryValid,
                        level: Hardware.memoryLevel
                    },
                    {
                        value: Hardware.cpuTemperature / 100,
                        valid: Hardware.cpuTemperatureValid,
                        level: Hardware.cpuTemperatureLevel
                    },
                    {
                        value: Hardware.diskValid ? Hardware.diskUsed / Hardware.diskTotal : 0,
                        valid: Hardware.diskValid,
                        level: Hardware.diskLevel
                    }
                ]

                delegate: ProgressBar {
                    required property var modelData

                    implicitWidth: 60
                    implicitHeight: 2
                    value: modelData.valid ? modelData.value : 0
                    level: modelData.level
                }
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 440
        onVisibleChanged: {
            if (visible)
                panel.selected = -1;
        }

        HardwarePanel {
            id: panel
        }
    }
}
