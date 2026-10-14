pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    property int selected: -1
    readonly property var metric: selected < 0 ? null : metrics[selected]
    readonly property var metrics: [
        {
            title: "CPU",
            value: Hardware.cpuValid ? Math.round(Hardware.cpuUsage * 100) + "%" : "—",
            readings: [],
            series: [],
            details: [["Model", "—"], ["Cores / threads", "—"], ["Clock speed", "—"], ["Load (1 / 5 / 15m)", "—"]]
        },
        {
            title: "GPU",
            value: "—",
            readings: [],
            series: [],
            details: [["Model", "—"], ["VRAM", "—"], ["Clock speed", "—"]]
        },
        {
            title: "Disk I/O",
            value: "—",
            readings: ["Read —", "Write —"],
            series: [],
            details: [["Device", "—"], ["Model", "—"], ["Interface", "—"]]
        },
        {
            title: "Network",
            value: "",
            readings: ["↓ " + root.speed(Traffic.rxBps), "↑ " + root.speed(Traffic.txBps)],
            series: [],
            details: [["Interface", "—"], ["Link speed", "—"]]
        },
        {
            title: "Memory",
            valid: Hardware.memoryValid,
            fraction: Hardware.memoryUsage,
            value: root.capacity(Hardware.memoryValid, Hardware.memoryUsed, Hardware.memoryTotal),
            available: Hardware.memoryValid ? root.gib(Hardware.memoryTotal - Hardware.memoryUsed) + " GiB available" : "—",
            details: [["Type", "—"], ["Speed", "—"], ["Swap", "—"]]
        },
        {
            title: "Disk /",
            valid: Hardware.diskValid,
            fraction: Hardware.diskValid ? Hardware.diskUsed / Hardware.diskTotal : 0,
            value: root.capacity(Hardware.diskValid, Hardware.diskUsed, Hardware.diskTotal),
            available: Hardware.diskValid ? root.gib(Hardware.diskAvailable) + " GiB available" : "—",
            details: [["Device", "—"], ["Model", "—"], ["Filesystem", "—"]]
        }
    ]

    spacing: 12

    function gib(bytes: real): string {
        return (bytes / 1024 ** 3).toFixed(1);
    }

    function capacity(valid: bool, used: real, total: real): string {
        return valid ? `${gib(used)} / ${gib(total)} GiB` : "—";
    }

    function speed(bytes: real): string {
        if (!Traffic.valid)
            return "—";
        const megabytes = bytes >= 1000000;
        return (bytes / (megabytes ? 1000000 : 1000)).toFixed(1) + (megabytes ? " MB/s" : " KB/s");
    }

    RowLayout {
        Text {
            Layout.fillWidth: true
            visible: root.selected < 0
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Medium
            text: "Hardware"
        }
        Button {
            visible: root.selected >= 0
            flat: true
            text: "Hardware"
            iconName: "go-previous-symbolic"
            onClicked: root.selected = -1
        }
        Text {
            visible: root.selected < 0
            color: Theme.textSecondary
            font.pixelSize: 11
            text: "Up —"
        }
    }

    GridLayout {
        columns: 2
        rowSpacing: 12
        columnSpacing: 12
        visible: root.selected < 0

        Repeater {
            model: 4
            TrendCard {
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                metric: root.metrics[index]
                onClicked: root.selected = index
            }
        }
        Repeater {
            model: 2
            CapacityCard {
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                metric: root.metrics[index + 4]
                onClicked: root.selected = index + 4
            }
        }
        Repeater {
            model: [
                {
                    title: "CPU temperature",
                    value: Hardware.cpuTemperature,
                    valid: Hardware.cpuTemperatureValid
                },
                {
                    title: "GPU temperature",
                    value: Hardware.gpuTemperature,
                    valid: Hardware.gpuTemperatureValid
                }
            ]
            WrapperRectangle {
                id: temperature
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 78
                margin: 12
                radius: 6
                color: Theme.barBackground

                ColumnLayout {
                    Text {
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        text: temperature.modelData.title
                    }
                    Text {
                        color: Theme.textPrimary
                        font.pixelSize: 24
                        text: temperature.modelData.valid ? Math.round(temperature.modelData.value) + "°C" : "—"
                    }
                }
            }
        }
    }

    ColumnLayout {
        spacing: 12
        visible: root.selected >= 0

        RowLayout {
            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 20
                text: root.metric?.title ?? ""
            }
            Text {
                color: Theme.textPrimary
                font.pixelSize: root.selected < 4 ? 22 : 14
                text: root.metric?.value ?? ""
            }
        }

        ColumnLayout {
            visible: root.selected < 4
            spacing: 6

            WrapperRectangle {
                Layout.fillWidth: true
                implicitHeight: 252
                margin: 12
                radius: 6
                color: Theme.barBackground

                Trend {
                    series: root.metric?.series ?? []
                }
            }
            RowLayout {
                Text {
                    Layout.fillWidth: true
                    color: Theme.textSecondary
                    font.pixelSize: 10
                    text: "−60s"
                }
                Text {
                    color: Theme.textSecondary
                    font.pixelSize: 10
                    text: "Now"
                }
            }
            RowLayout {
                Repeater {
                    model: root.metric?.readings ?? []
                    Text {
                        required property string modelData
                        Layout.fillWidth: true
                        color: Theme.textSecondary
                        text: modelData
                    }
                }
            }
            RowLayout {
                visible: root.selected < 2
                Repeater {
                    model: ["Average", "Peak"]
                    ColumnLayout {
                        id: statistic
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Text {
                            Layout.fillWidth: true
                            color: Theme.textSecondary
                            font.pixelSize: 11
                            text: statistic.modelData
                        }
                        Text {
                            color: Theme.textPrimary
                            font.pixelSize: 20
                            text: "—"
                        }
                    }
                }
            }
        }

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 128
            Layout.preferredHeight: 128
            visible: root.selected >= 4
            fraction: root.metric?.fraction ?? 0
            valid: root.metric?.valid ?? false
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.selected >= 4
            color: Theme.textSecondary
            text: root.metric?.available ?? ""
        }

        Separator {}

        Repeater {
            model: root.metric?.details ?? []
            RowLayout {
                id: detail
                required property var modelData
                Text {
                    Layout.fillWidth: true
                    color: Theme.textSecondary
                    text: detail.modelData[0]
                }
                Text {
                    color: Theme.textPrimary
                    text: detail.modelData[1]
                }
            }
        }
    }
}
