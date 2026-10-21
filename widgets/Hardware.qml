import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.widgets.hardware

BarButton {
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
                        value: HardwareService.cpu.usage,
                        valid: HardwareService.cpu.valid,
                        level: HardwareService.cpu.level
                    },
                    {
                        value: HardwareService.memory.usage,
                        valid: HardwareService.memory.valid,
                        level: HardwareService.memory.level
                    },
                    {
                        value: HardwareService.cpu.temperature / 100,
                        valid: HardwareService.cpu.temperatureValid,
                        level: HardwareService.cpu.temperatureLevel
                    },
                    {
                        value: HardwareService.filesystem.usage,
                        valid: HardwareService.filesystem.valid,
                        level: HardwareService.filesystem.level
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
