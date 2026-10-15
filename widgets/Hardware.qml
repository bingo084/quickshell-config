import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.config
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
                        warning: 0.5,
                        critical: 0.8
                    },
                    {
                        value: Hardware.memoryUsage,
                        valid: Hardware.memoryValid,
                        warning: 0.7,
                        critical: 0.9
                    },
                    {
                        value: Hardware.cpuTemperature / 100,
                        valid: Hardware.cpuTemperatureValid,
                        warning: 0.7,
                        critical: 0.9
                    },
                    {
                        value: Hardware.diskValid ? Hardware.diskUsed / Hardware.diskTotal : 0,
                        valid: Hardware.diskValid,
                        warning: 0.8,
                        critical: 0.9
                    }
                ]

                delegate: ProgressBar {
                    required property var modelData

                    implicitWidth: 60
                    implicitHeight: 2
                    value: modelData.valid ? modelData.value : 0
                    palette.highlight: {
                        const metric = modelData;
                        if (metric.value >= metric.critical)
                            return Theme.critical;
                        if (metric.value >= metric.warning)
                            return Theme.warning;
                        return Theme.accent;
                    }
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
