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
                        value: Hardware.cpu.usage,
                        valid: Hardware.cpu.valid,
                        level: Hardware.cpu.level
                    },
                    {
                        value: Hardware.memory.usage,
                        valid: Hardware.memory.valid,
                        level: Hardware.memory.level
                    },
                    {
                        value: Hardware.cpu.temperature / 100,
                        valid: Hardware.cpu.temperatureValid,
                        level: Hardware.cpu.temperatureLevel
                    },
                    {
                        value: Hardware.filesystem.usage,
                        valid: Hardware.filesystem.valid,
                        level: Hardware.filesystem.level
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
