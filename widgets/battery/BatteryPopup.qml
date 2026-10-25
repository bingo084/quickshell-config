pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.config

Popup {
    id: root
    readonly property var devices: UPower.devices.values.filter(device => device.ready && device.type !== UPowerDeviceType.LinePower) // qmllint disable missing-property
    readonly property UPowerDevice battery: devices.find(device => device.isLaptopBattery && device.isPresent) ?? null
    readonly property var peripherals: devices.filter(device => device !== battery)
    readonly property var stats: {
        if (!battery)
            return [];
        const items = [];
        if (battery.healthSupported)
            items.push(["Health", Math.round(battery.healthPercentage) + "%"]);
        if (battery.energyCapacity > 0) {
            items.push(["Power", (battery.changeRate > 0 ? "+" : "") + battery.changeRate.toFixed(1) + " W"]);
            items.push(["Energy", battery.energy.toFixed(1) + " / " + battery.energyCapacity.toFixed(1) + " Wh"]);
        }
        return items;
    }
    readonly property string status: {
        if (!battery)
            return "";
        const parts = [battery.state === UPowerDeviceState.Discharging ? "On battery" : UPowerDeviceState.toString(battery.state)];
        if (battery.timeToEmpty > 0)
            parts.push("About " + formatDuration(battery.timeToEmpty) + " remaining");
        else if (battery.timeToFull > 0)
            parts.push("Full in " + formatDuration(battery.timeToFull));
        return parts.join(" · ");
    }

    contentWidth: 316
    contentMargin: 14

    function formatDuration(seconds: real): string {
        const total = Math.ceil(seconds / 60);
        const hours = Math.floor(total / 60);
        const minutes = total % 60;
        return hours > 0 ? hours + "h" + (minutes > 0 ? " " + minutes + "m" : "") : minutes + "m";
    }

    Flickable {
        Text {
            text: "Battery"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        ColumnLayout {
            visible: root.battery !== null
            spacing: 8

            RowLayout {
                Layout.fillWidth: false
                spacing: 6
                Icon {
                    name: "laptop-symbolic"
                    color: Theme.textSecondary
                }
                Text {
                    id: batteryName
                    text: "Laptop battery"
                    font.pixelSize: 13
                    color: Theme.textPrimary

                    Tooltip {
                        anchorItem: batteryName
                        enabled: text !== ""
                        text: root.battery?.model ?? ""
                    }
                }
            }

            RowLayout {
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    text: Math.round((root.battery?.percentage ?? 0) * 100) + "%"
                    font.pixelSize: 30
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                }
                Gauge {
                    implicitWidth: 48
                    implicitHeight: 23
                    fraction: root.battery?.percentage ?? 0
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.status
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }

        Text {
            visible: root.battery === null
            text: UPower.displayDevice.ready ? "No laptop battery" : "Loading battery…"
            font.pixelSize: 13
            color: Theme.textSecondary
        }

        RowLayout {
            visible: root.stats.length > 0
            uniformCellSizes: true
            Repeater {
                model: root.stats
                ColumnLayout {
                    id: stat
                    required property var modelData
                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        text: stat.modelData[0]
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: stat.modelData[1]
                        font.pixelSize: 12
                        color: Theme.textPrimary
                    }
                }
            }
        }

        Separator {
            visible: root.peripherals.length > 0
        }
        Text {
            visible: root.peripherals.length > 0
            text: "Devices"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
        Devices {
            devices: root.peripherals
        }

        Separator {}
        Text {
            text: "Power mode"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
        PowerModes {
            animated: root.visible
        }
        Text {
            Layout.fillWidth: true
            visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            text: PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? "Performance limited while on lap" : "Performance limited by temperature"
            font.pixelSize: 11
            color: Theme.warning
            wrapMode: Text.Wrap
        }
    }
}
