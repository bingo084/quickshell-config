pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.config

ColumnLayout {
    id: root
    required property var devices
    readonly property real percentageWidth: Math.ceil(Math.max(0, ...devices.map(device => percentageMetrics.advanceWidth(Math.round(device.percentage * 100) + "%"))))
    readonly property var deviceIcons: ({
            [UPowerDeviceType.Battery]: "battery-symbolic",
            [UPowerDeviceType.BluetoothGeneric]: "bluetooth-symbolic",
            [UPowerDeviceType.Camera]: "camera-photo-symbolic",
            [UPowerDeviceType.Computer]: "computer-symbolic",
            [UPowerDeviceType.GamingInput]: "input-gaming-symbolic",
            [UPowerDeviceType.Headphones]: "audio-headphones-symbolic",
            [UPowerDeviceType.Headset]: "audio-headset-symbolic",
            [UPowerDeviceType.Keyboard]: "input-keyboard-symbolic",
            [UPowerDeviceType.MediaPlayer]: "multimedia-player-symbolic",
            [UPowerDeviceType.Modem]: "modem-symbolic",
            [UPowerDeviceType.Monitor]: "video-display-symbolic",
            [UPowerDeviceType.Mouse]: "input-mouse-symbolic",
            [UPowerDeviceType.Network]: "network-wired-symbolic",
            [UPowerDeviceType.OtherAudio]: "audio-card-symbolic",
            [UPowerDeviceType.Pda]: "pda-symbolic",
            [UPowerDeviceType.Pen]: "input-tablet-symbolic",
            [UPowerDeviceType.Phone]: "phone-symbolic",
            [UPowerDeviceType.Printer]: "printer-symbolic",
            [UPowerDeviceType.RemoteControl]: "input-gaming-symbolic",
            [UPowerDeviceType.Scanner]: "scanner-symbolic",
            [UPowerDeviceType.Speakers]: "audio-speakers-symbolic",
            [UPowerDeviceType.Tablet]: "input-tablet-symbolic",
            [UPowerDeviceType.Touchpad]: "input-touchpad-symbolic",
            [UPowerDeviceType.Toy]: "applications-games-symbolic",
            [UPowerDeviceType.Ups]: "uninterruptible-power-supply-symbolic",
            [UPowerDeviceType.Video]: "camera-video-symbolic",
            [UPowerDeviceType.Wearable]: "bluetooth-symbolic"
        })

    spacing: 12

    FontMetrics {
        id: percentageMetrics
        font.pixelSize: 12
    }

    Repeater {
        model: root.devices
        RowLayout {
            id: row
            required property UPowerDevice modelData
            spacing: 6
            Icon {
                name: row.modelData.isLaptopBattery ? "laptop-symbolic" : root.deviceIcons[row.modelData.type] || "battery-missing-symbolic"
                color: Theme.textSecondary
            }
            Text {
                id: name
                Layout.fillWidth: true
                text: row.modelData.model || UPowerDeviceType.toString(row.modelData.type)
                font.pixelSize: 13
                color: Theme.textPrimary
                elide: Text.ElideRight

                Tooltip {
                    anchorItem: name
                    enabled: name.truncated
                    text: name.text
                }
            }
            RowLayout {
                spacing: 4
                BatteryIcon {
                    id: batteryIcon
                    device: row.modelData

                    Tooltip {
                        anchorItem: batteryIcon
                        text: UPowerDeviceState.toString(row.modelData.state)
                        enabled: row.modelData.state !== UPowerDeviceState.Unknown
                    }
                }
                Text {
                    Layout.minimumWidth: root.percentageWidth
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(row.modelData.percentage * 100) + "%"
                    color: Theme.textPrimary
                    font: percentageMetrics.font
                }
            }
        }
    }
}
