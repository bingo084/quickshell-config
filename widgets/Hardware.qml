import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    onClicked: popup.visible = !popup.visible
    content: RowLayout {
        spacing: 6
        IconImage {
            implicitSize: 16
            source: Quickshell.iconPath("utilities-system-monitor-symbolic")
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
                delegate: Rectangle {
                    id: track
                    required property var modelData
                    implicitWidth: 60
                    implicitHeight: 3
                    radius: height / 2
                    color: Theme.meterBackground
                    Rectangle {
                        width: track.modelData.valid ? track.width * Math.max(0, Math.min(1, track.modelData.value)) : 0
                        height: track.height
                        radius: track.radius
                        color: {
                            const metric = track.modelData;
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
                text: Hardware.cpuTemperatureValid ? "CPU temperature: " + Math.round(Hardware.cpuTemperature) + "°C" : "CPU temperature: —"
            }
            Text {
                color: Theme.textPrimary
                text: Hardware.gpuTemperatureValid ? "GPU temperature: " + Math.round(Hardware.gpuTemperature) + "°C" : "GPU temperature: —"
            }
            Text {
                color: Theme.textPrimary
                text: Hardware.memoryValid ? "RAM: " + (Hardware.memoryUsed / 1024 ** 3).toFixed(1) + " / " + (Hardware.memoryTotal / 1024 ** 3).toFixed(1) + " GiB" : "RAM: —"
            }
            Text {
                color: Theme.textPrimary
                text: {
                    if (!Hardware.diskValid)
                        return "Disk (/): —";
                    const used = (Hardware.diskUsed / 1024 ** 3).toFixed(1);
                    const total = (Hardware.diskTotal / 1024 ** 3).toFixed(1);
                    const available = (Hardware.diskAvailable / 1024 ** 3).toFixed(1);
                    return `Disk (/): ${used} / ${total} GiB (${available} GiB available)`;
                }
            }
        }
    }
}
