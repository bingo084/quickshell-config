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
            level: Hardware.cpu.level,
            value: Hardware.cpu.valid ? Math.round(Hardware.cpu.usage * 100) + "%" : "—",
            readings: [],
            series: [Hardware.cpu.history],
            maximum: 100,
            statistics: [["Average", Hardware.cpu.stats ? Math.round(Hardware.cpu.stats.average) + "%" : "—"], ["Peak", Hardware.cpu.stats ? Math.round(Hardware.cpu.stats.peak) + "%" : "—"]],
            details: [["Model", Hardware.cpu.info?.model || "—"], ["Cores / threads", Hardware.cpu.info ? `${Hardware.cpu.info.cores ?? "—"} / ${Hardware.cpu.info.threads}` : "—"], ["Average clock", Hardware.cpu.clock >= 0 ? (Hardware.cpu.clock / 1000).toFixed(2) + " GHz" : "—"], ["Load (1 / 5 / 15m)", Hardware.cpu.loadAverage.map(value => value.toFixed(2)).join(" / ") || "—"]]
        },
        {
            title: "GPU",
            level: Hardware.gpu.level,
            value: Hardware.gpu.valid ? Math.round(Hardware.gpu.usage * 100) + "%" : "—",
            readings: [],
            series: [Hardware.gpu.history],
            statistics: [["Average", Hardware.gpu.stats ? Math.round(Hardware.gpu.stats.average) + "%" : "—"], ["Peak", Hardware.gpu.stats ? Math.round(Hardware.gpu.stats.peak) + "%" : "—"]],
            details: [["Model", Hardware.gpu.model || "—"], ["VRAM", Hardware.gpu.sample?.memoryUsed != null && Hardware.gpu.sample?.memoryTotal != null ? root.capacity(true, Hardware.gpu.sample.memoryUsed, Hardware.gpu.sample.memoryTotal) : "—"], ["Clock speed", Hardware.gpu.sample?.clock != null ? Math.round(Hardware.gpu.sample.clock) + " MHz" : "—"]]
        },
        {
            title: "Disk I/O",
            level: 0,
            value: "",
            readings: ["Read " + root.speed(Hardware.diskIo.valid, Hardware.diskIo.readBps), "Write " + root.speed(Hardware.diskIo.valid, Hardware.diskIo.writeBps)],
            series: [Hardware.diskIo.history.map(point => ({
                            time: point.time,
                            value: point.read
                        })), Hardware.diskIo.history.map(point => ({
                            time: point.time,
                            value: point.write
                        }))],
            maximum: Math.max(1000, Hardware.diskIo.peak),
            details: [["Device", Hardware.diskIo.devices.join(", ") || "—"], ["Model", root.diskDetail("model")], ["Interface", root.diskDetail("tran").toUpperCase()]]
        },
        {
            title: "Network",
            level: 0,
            value: "",
            readings: ["↓ " + root.speed(Traffic.valid, Traffic.rxBps), "↑ " + root.speed(Traffic.valid, Traffic.txBps)],
            series: [Traffic.history.map(point => ({
                            time: point.time,
                            value: point.rx
                        })), Traffic.history.map(point => ({
                            time: point.time,
                            value: point.tx
                        }))],
            maximum: Math.max(1000, Traffic.peak),
            details: [["Interfaces", Traffic.interfaces.join(", ") || "—"], ["Wired link", Network.wired?.linkSpeed > 0 ? Network.wired.linkSpeed + " Mbps" : "—"], ["Wi-Fi link", Network.wifiLink > 0 ? Network.wifiLink + " Mbps" : "—"], ["Wi-Fi signal", Network.wifiNetwork ? Math.round(Network.wifiNetwork.signalStrength * 100) + "%" : "—"]]
        },
        {
            title: "Memory",
            level: Hardware.memory.level,
            valid: Hardware.memory.valid,
            fraction: Hardware.memory.usage,
            value: root.capacity(Hardware.memory.valid, Hardware.memory.used, Hardware.memory.total),
            available: Hardware.memory.valid ? root.gib(Hardware.memory.total - Hardware.memory.used) + " GiB available" : "—",
            details: [["Type", Hardware.memory.info?.types.join(" / ") || "—"], ["Speed", Hardware.memory.info?.speeds.length > 0 ? Hardware.memory.info.speeds.join(" / ") + " MT/s" : "—"], ["Swap", Hardware.memory.swap ? (Hardware.memory.swap.total === 0 ? "None" : root.capacity(true, Hardware.memory.swap.used, Hardware.memory.swap.total)) : "—"]]
        },
        {
            title: "Disk /",
            level: Hardware.filesystem.level,
            valid: Hardware.filesystem.valid,
            fraction: Hardware.filesystem.usage,
            value: root.capacity(Hardware.filesystem.valid, Hardware.filesystem.used, Hardware.filesystem.total),
            available: Hardware.filesystem.valid ? root.gib(Hardware.filesystem.available) + " GiB available" : "—",
            details: [["Device", Hardware.filesystem.info?.device || "—"], ["Model", Hardware.filesystem.info?.model || "—"], ["Filesystem", Hardware.filesystem.info?.fstype || "—"]]
        }
    ]

    spacing: 12

    onSelectedChanged: {
        if (selected === 3)
            Network.refreshWifiLink();
    }

    function diskDetail(field: string): string {
        const values = Hardware.diskIo.info.filter(device => Hardware.diskIo.devices.includes(device.name)).map(device => device[field]?.trim()).filter(Boolean);
        return [...new Set(values)].join(", ") || "—";
    }

    function uptime(seconds: real): string {
        if (seconds < 0)
            return "—";
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return `${days} d ${hours % 24} h`;
        return `${hours} h ${minutes % 60} m`;
    }

    function gib(bytes: real): string {
        return (bytes / 1024 ** 3).toFixed(1);
    }

    function capacity(valid: bool, used: real, total: real): string {
        return valid ? `${gib(used)} / ${gib(total)} GiB` : "—";
    }

    function speed(valid: bool, bytes: real): string {
        if (!valid)
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
            text: "Hardware"
            iconName: "go-previous-symbolic"
            onClicked: root.selected = -1
        }
        Text {
            visible: root.selected < 0
            color: Theme.textSecondary
            font.pixelSize: 11
            text: "Up  " + root.uptime(Hardware.uptime)
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
                    level: Hardware.cpu.temperatureLevel,
                    value: Hardware.cpu.temperature,
                    valid: Hardware.cpu.temperatureValid
                },
                {
                    title: "GPU temperature",
                    level: Hardware.gpu.temperatureLevel,
                    value: Hardware.gpu.temperature,
                    valid: Hardware.gpu.temperatureValid
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
                        color: Theme.levelColor(temperature.modelData.level)
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
                color: Theme.levelColor(root.metric?.level ?? 0)
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
                    maximum: root.metric?.maximum ?? 100
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
                    model: root.metric?.statistics ?? []
                    ColumnLayout {
                        id: statistic
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Text {
                            Layout.fillWidth: true
                            color: Theme.textSecondary
                            font.pixelSize: 11
                            text: statistic.modelData[0]
                        }
                        Text {
                            color: Theme.textPrimary
                            font.pixelSize: 20
                            text: statistic.modelData[1]
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
            level: root.metric?.level ?? 0
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
