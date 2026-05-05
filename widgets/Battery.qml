pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

WrapperRectangle {
    id: root
    radius: 4
    color: Qt.darker("#ffffff", area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

    readonly property var deviceIcons: ({
            [UPowerDeviceType.Pen]: "input-tablet-symbolic",
            [UPowerDeviceType.MediaPlayer]: "multimedia-player-symbolic",
            [UPowerDeviceType.Pda]: "pda-symbolic",
            [UPowerDeviceType.Keyboard]: "input-keyboard-symbolic",
            [UPowerDeviceType.Touchpad]: "input-touchpad-symbolic",
            [UPowerDeviceType.Printer]: "printer-symbolic",
            [UPowerDeviceType.Ups]: "uninterruptible-power-supply-symbolic",
            [UPowerDeviceType.Tablet]: "input-tablet-symbolic",
            [UPowerDeviceType.Modem]: "modem-symbolic",
            [UPowerDeviceType.BluetoothGeneric]: "bluetooth-symbolic",
            [UPowerDeviceType.OtherAudio]: "audio-card-symbolic",
            [UPowerDeviceType.Headphones]: "audio-headphones-symbolic",
            [UPowerDeviceType.GamingInput]: "input-gaming-symbolic",
            [UPowerDeviceType.Phone]: "phone-symbolic",
            [UPowerDeviceType.Wearable]: "bluetooth-symbolic",
            [UPowerDeviceType.Network]: "network-wired-symbolic",
            [UPowerDeviceType.Video]: "camera-video-symbolic",
            [UPowerDeviceType.Mouse]: "input-mouse-symbolic",
            [UPowerDeviceType.Computer]: "computer-symbolic",
            [UPowerDeviceType.Camera]: "camera-photo-symbolic",
            [UPowerDeviceType.RemoteControl]: "input-gaming-symbolic",
            [UPowerDeviceType.LinePower]: "ac-adapter-symbolic",
            [UPowerDeviceType.Headset]: "audio-headset-symbolic",
            [UPowerDeviceType.Unknown]: "battery-missing-symbolic",
            [UPowerDeviceType.Battery]: "battery-symbolic",
            [UPowerDeviceType.Scanner]: "scanner-symbolic",
            [UPowerDeviceType.Speakers]: "audio-speakers-symbolic",
            [UPowerDeviceType.Toy]: "applications-games-symbolic",
            [UPowerDeviceType.Monitor]: "video-display-symbolic"
        })

    function iconName(device) {
        if (!device.ready || !device.isPresent)
            return device.iconName || "battery-missing-symbolic";
        if (device.state === UPowerDeviceState.FullyCharged)
            return "battery-level-100-charged-symbolic";

        const level = Math.round(device.percentage * 10) * 10;
        if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
            return "battery-level-" + Math.min(90, level) + "-charging-symbolic";
        return "battery-level-" + level + "-symbolic";
    }

    WrapperMouseArea {
        id: area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6

        onClicked: {
            // qmllint disable unresolved-type
            menu.anchor.updateAnchor();
            // qmllint enable unresolved-type
            menu.visible = !menu.visible;
        }

        RowLayout {
            id: row
            spacing: 4

            IconImage {
                implicitSize: 18
                source: Quickshell.iconPath(root.iconName(UPower.displayDevice))
            }

            Text {
                color: "#1a1a1a"
                text: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "--%"
            }
        }
    }

    PopupWindow {
        id: menu
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight
        color: "transparent"
        anchor {
            item: root
            // qmllint disable missing-type
            edges: Edges.Bottom
            gravity: Edges.Bottom
            // qmllint enable missing-type
            margins.bottom: -4
        }

        WrapperRectangle {
            id: background
            radius: 8
            color: "#ffffff"
            border.color: "#dcdcdc"
            border.width: 1
            margin: 8

            property real percentageWidth: 0

            ColumnLayout {
                spacing: 6

                Repeater {
                    model: UPower.devices.values.filter(device => device.ready && device.type !== UPowerDeviceType.LinePower)

                    ColumnLayout {
                        id: device
                        spacing: 2

                        required property UPowerDevice modelData
                        readonly property string typeIcon: modelData.isLaptopBattery ? "laptop-symbolic" : root.deviceIcons[modelData.type] || "battery-missing-symbolic"
                        readonly property int iconSize: 18
                        readonly property int rowSpacing: 6
                        readonly property int detailIndent: iconSize + rowSpacing

                        readonly property string label: {
                            if (modelData.isLaptopBattery)
                                return !modelData.model || modelData.model === "standard" ? "Laptop" : modelData.model;
                            return modelData.model || UPowerDeviceType.toString(modelData.type);
                        }

                        readonly property string statusDetail: {
                            const parts = [UPowerDeviceState.toString(modelData.state)];
                            const timeSeconds = modelData.timeToEmpty > 0 ? modelData.timeToEmpty : modelData.timeToFull;

                            if (modelData.type === UPowerDeviceType.Battery && !modelData.isPresent)
                                parts.push("Not present");
                            if (timeSeconds > 0) {
                                const timeHours = Math.floor(timeSeconds / 3600);
                                const timeMinutes = Math.floor((timeSeconds % 3600) / 60);
                                const timeLabel = modelData.timeToEmpty > 0 ? "Empty in" : "Full in";
                                parts.push(timeLabel + ": " + timeHours + "h " + timeMinutes + "m");
                            }

                            return parts.join(" / ");
                        }

                        readonly property string capacityDetail: {
                            const parts = [];

                            if (modelData.energyCapacity > 0)
                                parts.push("Energy: " + modelData.energy.toFixed(1) + "/" + modelData.energyCapacity.toFixed(1) + " Wh");
                            if (Math.abs(modelData.changeRate) > 0)
                                parts.push("Rate: " + (modelData.changeRate > 0 ? "+" : "") + modelData.changeRate.toFixed(1) + " W");
                            if (modelData.healthSupported)
                                parts.push("Health: " + Math.round(modelData.healthPercentage) + "%");

                            return parts.join(" / ");
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: device.rowSpacing

                            IconImage {
                                implicitSize: device.iconSize
                                source: Quickshell.iconPath(device.typeIcon, "battery-symbolic")
                            }
                            Text {
                                Layout.fillWidth: true
                                color: "#1a1a1a"
                                elide: Text.ElideRight
                                text: device.label
                            }
                            IconImage {
                                implicitSize: device.iconSize
                                source: Quickshell.iconPath(root.iconName(device.modelData))
                            }
                            Text {
                                Layout.preferredWidth: background.percentageWidth || implicitWidth
                                color: "#1a1a1a"
                                text: Math.round(device.modelData.percentage * 100) + "%"

                                onImplicitWidthChanged: background.percentageWidth = Math.max(background.percentageWidth, implicitWidth)
                            }
                        }

                        Text {
                            Layout.leftMargin: device.detailIndent
                            color: "#666666"
                            font.pixelSize: 11
                            text: device.statusDetail
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.leftMargin: device.detailIndent
                            color: "#777777"
                            font.pixelSize: 11
                            text: device.capacityDetail
                            visible: device.capacityDetail !== ""
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
