pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarButton {
    id: root
    property int range: 120

    Component.onCompleted: range = InhibitService.duration > 240 ? 480 : InhibitService.duration > 120 ? 240 : 120

    function formatDuration(minutes: real): string {
        const total = Math.ceil(minutes);
        const hours = Math.floor(total / 60);
        const rest = total % 60;
        return hours > 0 ? `${hours}h` + (rest > 0 ? ` ${rest}m` : "") : `${rest}m`;
    }

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else {
            popup.closeOthers();
            InhibitService.cycle();
        }
    }

    content: Icon {
        id: inhibitIcon
        name: "inhibit-symbolic"

        Rectangle {
            id: statusBadge
            // Keep the badge proportions in the theme icon's 16px grid.
            readonly property real unit: inhibitIcon.width / 16
            anchors.right: inhibitIcon.right
            anchors.bottom: inhibitIcon.bottom
            anchors.margins: -unit
            width: 9 * unit
            height: width
            radius: width / 2
            visible: InhibitService.mode !== "off"
            color: InhibitService.mode === "awake" ? Theme.warning : Theme.critical

            Rectangle {
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                width: 5 * statusBadge.unit
                height: statusBadge.unit
                color: Qt.alpha(Theme.background, 1)
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        preferredWidth: 320

        ColumnLayout {
            spacing: 10

            SegmentedControl {
                readonly property color modeColor: InhibitService.mode === "off" ? Theme.textPrimary : InhibitService.mode === "awake" ? Theme.warning : Theme.critical

                animated: popup.visible
                currentIndex: model.findIndex(mode => mode.value === InhibitService.mode)
                onActivated: index => InhibitService.setMode(model[index].value)
                palette.mid: Theme.border
                palette.highlightedText: modeColor
                model: [
                    {
                        text: "Off",
                        value: "off"
                    },
                    {
                        text: "Awake",
                        value: "awake"
                    },
                    {
                        text: "Active",
                        value: "active"
                    }
                ]
            }

            Separator {}

            ColumnLayout {
                enabled: InhibitService.mode !== "off"
                opacity: enabled ? 1 : 0.5
                spacing: 8

                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "Duration"
                        font: unlimitedButton.font
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.textSecondary
                    }
                    DurationButton {
                        id: unlimitedButton
                        implicitHeight: 28
                        text: "Unlimited"
                        highlighted: InhibitService.duration === 0
                        onClicked: {
                            root.range = 120;
                            InhibitService.setDuration(0);
                        }
                    }
                }

                RowLayout {
                    spacing: 6

                    Repeater {
                        model: [30, 60, 120, 240, 480]
                        delegate: DurationButton {
                            required property int modelData

                            Layout.fillWidth: true
                            implicitWidth: 50
                            text: root.formatDuration(modelData)
                            highlighted: InhibitService.duration === modelData
                            onClicked: {
                                root.range = Math.max(120, modelData);
                                InhibitService.setDuration(modelData);
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: InhibitService.expiresAt > 0
                    spacing: 0

                    RowLayout {
                        Text {
                            Layout.fillWidth: true
                            text: root.formatDuration(countdown.minutes) + " left"
                            font.pixelSize: 12
                            color: Theme.textPrimary
                        }
                        Text {
                            readonly property double deadline: countdown.pressed ? InhibitService.now + countdown.minutes * 60000 : InhibitService.expiresAt

                            text: "Until " + Qt.formatDateTime(new Date(deadline), "hh:mm")
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                    }

                    Slider {
                        id: countdown
                        readonly property real minutes: pressed ? valueAt(position) : InhibitService.remaining

                        Layout.fillWidth: true
                        leftPadding: minimumLabel.implicitWidth + 6
                        rightPadding: maximumLabel.implicitWidth + 6
                        from: 1
                        to: root.range
                        value: InhibitService.remaining
                        stepSize: 1
                        snapMode: Controls.Slider.SnapAlways
                        live: false
                        wheelEnabled: !pressed
                        onPressedChanged: {
                            if (pressed) {
                                value = InhibitService.remaining;
                                return;
                            }
                            InhibitService.setDuration(value);
                            value = Qt.binding(() => InhibitService.remaining);
                        }
                        onMoved: {
                            if (!pressed)
                                InhibitService.setDuration(Math.ceil(value));
                        }
                        Text {
                            id: minimumLabel
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: countdown.hovered || countdown.pressed
                            text: "1m"
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                        Text {
                            id: maximumLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: countdown.hovered || countdown.pressed
                            text: root.formatDuration(countdown.to)
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }
                }
            }
        }
    }

    component DurationButton: Controls.Button {
        id: control
        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
        implicitHeight: 30
        horizontalPadding: 8
        font.pixelSize: 12
        contentItem: Text {
            text: control.text
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: control.highlighted ? Theme.accent : Theme.textPrimary
        }
        background: Rectangle {
            radius: 4
            border.width: control.visualFocus ? 1 : 0
            border.color: Theme.accent
            color: Qt.tint(control.highlighted ? Theme.selectedBackground : Theme.controlBackground, control.down ? Theme.pressOverlay : control.hovered ? Theme.hoverOverlay : "transparent")
        }
    }
}
