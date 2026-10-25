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
            level: HardwareService.cpu.level,
            value: HardwareService.cpu.valid ? Math.round(HardwareService.cpu.usage * 100) + "%" : "—",
            readings: [],
            series: [HardwareService.cpu.history],
            maximum: 100,
            statistics: [["Average", HardwareService.cpu.stats ? Math.round(HardwareService.cpu.stats.average) + "%" : "—"], ["Peak", HardwareService.cpu.stats ? Math.round(HardwareService.cpu.stats.peak) + "%" : "—"]],
            details: [["Model", HardwareService.cpu.info?.model || "—"], ["Cores / threads", HardwareService.cpu.info ? `${HardwareService.cpu.info.cores ?? "—"} / ${HardwareService.cpu.info.threads}` : "—"], ["Average clock", HardwareService.cpu.clock >= 0 ? (HardwareService.cpu.clock / 1000).toFixed(2) + " GHz" : "—"], ["Load (1 / 5 / 15m)", HardwareService.cpu.loadAverage.map(value => value.toFixed(2)).join(" / ") || "—"]]
        },
        {
            title: "GPU",
            level: HardwareService.gpu.level,
            value: HardwareService.gpu.valid ? Math.round(HardwareService.gpu.usage * 100) + "%" : "—",
            readings: [],
            series: [HardwareService.gpu.history],
            statistics: [["Average", HardwareService.gpu.stats ? Math.round(HardwareService.gpu.stats.average) + "%" : "—"], ["Peak", HardwareService.gpu.stats ? Math.round(HardwareService.gpu.stats.peak) + "%" : "—"]],
            details: [["Model", HardwareService.gpu.model || "—"], ["VRAM", HardwareService.gpu.sample?.memoryUsed != null && HardwareService.gpu.sample?.memoryTotal != null ? root.capacity(true, HardwareService.gpu.sample.memoryUsed, HardwareService.gpu.sample.memoryTotal) : "—"], ["Clock speed", HardwareService.gpu.sample?.clock != null ? Math.round(HardwareService.gpu.sample.clock) + " MHz" : "—"]]
        },
        {
            title: "Disk I/O",
            level: 0,
            value: "",
            readings: ["Read " + root.speed(HardwareService.diskIo.valid, HardwareService.diskIo.readBps), "Write " + root.speed(HardwareService.diskIo.valid, HardwareService.diskIo.writeBps)],
            series: [HardwareService.diskIo.history.map(point => ({
                            time: point.time,
                            value: point.read
                        })), HardwareService.diskIo.history.map(point => ({
                            time: point.time,
                            value: point.write
                        }))],
            maximum: Math.max(1000, HardwareService.diskIo.peak),
            details: [["Device", HardwareService.diskIo.devices.join(", ") || "—"], ["Model", root.diskDetail("model")], ["Interface", root.diskDetail("tran").toUpperCase()]]
        },
        {
            title: "Network",
            level: 0,
            value: "",
            readings: ["↓ " + root.speed(TrafficService.valid, TrafficService.rxBps), "↑ " + root.speed(TrafficService.valid, TrafficService.txBps)],
            series: [TrafficService.history.map(point => ({
                            time: point.time,
                            value: point.rx
                        })), TrafficService.history.map(point => ({
                            time: point.time,
                            value: point.tx
                        }))],
            maximum: Math.max(1000, TrafficService.peak),
            details: [["Interfaces", TrafficService.interfaces.join(", ") || "—"], ["Wired link", NetworkService.wired?.linkSpeed > 0 ? NetworkService.wired.linkSpeed + " Mbps" : "—"], ["Wi-Fi link", NetworkService.wifiLink?.speed > 0 ? NetworkService.wifiLink.speed + " Mbps" : "—"], ["Wi-Fi signal", NetworkService.wifiNetwork ? Math.round(NetworkService.wifiNetwork.signalStrength * 100) + "%" : "—"]]
        },
        {
            title: "Memory",
            level: HardwareService.memory.level,
            valid: HardwareService.memory.valid,
            fraction: HardwareService.memory.usage,
            value: root.capacity(HardwareService.memory.valid, HardwareService.memory.used, HardwareService.memory.total),
            available: HardwareService.memory.valid ? root.gib(HardwareService.memory.total - HardwareService.memory.used) + " GiB available" : "—",
            details: [["Type", HardwareService.memory.info?.types.join(" / ") || "—"], ["Speed", HardwareService.memory.info?.speeds.length > 0 ? HardwareService.memory.info.speeds.join(" / ") + " MT/s" : "—"], ["Swap", HardwareService.memory.swap ? (HardwareService.memory.swap.total === 0 ? "None" : root.capacity(true, HardwareService.memory.swap.used, HardwareService.memory.swap.total)) : "—"]]
        },
        {
            title: "Disk /",
            level: HardwareService.filesystem.level,
            valid: HardwareService.filesystem.valid,
            fraction: HardwareService.filesystem.usage,
            value: root.capacity(HardwareService.filesystem.valid, HardwareService.filesystem.used, HardwareService.filesystem.total),
            available: HardwareService.filesystem.valid ? root.gib(HardwareService.filesystem.available) + " GiB available" : "—",
            details: [["Device", HardwareService.filesystem.info?.device || "—"], ["Model", HardwareService.filesystem.info?.model || "—"], ["Filesystem", HardwareService.filesystem.info?.fstype || "—"]]
        }
    ]

    spacing: 12

    onSelectedChanged: {
        if (selected === 3)
            NetworkService.refreshWifiLink();
    }

    function diskDetail(field: string): string {
        const values = HardwareService.diskIo.info.filter(device => HardwareService.diskIo.devices.includes(device.name)).map(device => device[field]?.trim()).filter(Boolean);
        return [...new Set(values)].join(", ") || "—";
    }

    function uptime(seconds: real): string {
        if (seconds < 0)
            return "—";
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return `${days}d ${hours % 24}h`;
        return `${hours}h ${minutes % 60}m`;
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
            font.weight: Font.DemiBold
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
            text: "Up  " + root.uptime(HardwareService.uptime)
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
                    level: HardwareService.cpu.temperatureLevel,
                    value: HardwareService.cpu.temperature,
                    valid: HardwareService.cpu.temperatureValid
                },
                {
                    title: "GPU temperature",
                    level: HardwareService.gpu.temperatureLevel,
                    value: HardwareService.gpu.temperature,
                    valid: HardwareService.gpu.temperatureValid
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
                color: Theme.cardBackground
                border.width: 1
                border.color: Theme.cardBorder

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
                color: Theme.cardBackground
                border.width: 1
                border.color: Theme.cardBorder

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
