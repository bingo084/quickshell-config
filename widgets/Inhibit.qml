pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    property int range: 120

    Component.onCompleted: range = Inhibit.duration > 240 ? 480 : Inhibit.duration > 120 ? 240 : 120

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
            Inhibit.cycle();
        }
    }

    content: Icon {
        implicitSize: 18
        color: Inhibit.mode === "off" ? Theme.textPrimary : Inhibit.mode === "awake" ? Theme.warning : Theme.critical
        source: Qt.resolvedUrl("../assets/coffee.svg")
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 280

        ColumnLayout {
            spacing: 10

            Rectangle {
                id: modeSelector
                readonly property Item selectedButton: modeButtons.count > 0 ? modeButtons.itemAt(Inhibit.mode === "off" ? 0 : Inhibit.mode === "awake" ? 1 : 2) : null

                Layout.fillWidth: true
                implicitHeight: 34
                radius: 6
                color: Qt.tint(Theme.meterBackground, Theme.hoveredBackground)

                Rectangle {
                    readonly property color modeColor: Inhibit.mode === "off" ? Theme.textPrimary : Inhibit.mode === "awake" ? Theme.warning : Theme.critical

                    x: modeRow.x + (modeSelector.selectedButton?.x ?? 0)
                    y: modeRow.y
                    width: modeSelector.selectedButton?.width ?? 0
                    height: modeRow.height
                    radius: 4
                    border.width: 1
                    border.color: Inhibit.mode === "off" ? Theme.popupBorder : Qt.alpha(modeColor, 0.4)
                    color: Inhibit.mode === "off" ? Theme.popupBackground : Qt.tint(Theme.popupBackground, Qt.alpha(modeColor, 0.4))

                    Behavior on x {
                        enabled: popup.visible
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        enabled: popup.visible
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on border.color {
                        enabled: popup.visible
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                RowLayout {
                    id: modeRow
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0

                    Repeater {
                        id: modeButtons
                        model: ["off", "awake", "active"]

                        delegate: Controls.Button {
                            id: modeButton
                            required property string modelData
                            readonly property color modeColor: modelData === "off" ? Theme.textPrimary : modelData === "awake" ? Theme.warning : Theme.critical

                            Layout.fillWidth: true
                            implicitWidth: 80
                            implicitHeight: 28
                            text: modelData
                            font.pixelSize: 12
                            font.capitalization: Font.Capitalize
                            checkable: true
                            autoExclusive: true
                            checked: Inhibit.mode === modelData
                            onClicked: Inhibit.setMode(modelData)
                            contentItem: Text {
                                text: modeButton.text
                                font: modeButton.font
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: modeButton.checked ? modeButton.modeColor : modeButton.hovered || modeButton.down ? Theme.textPrimary : Theme.textSecondary

                                Behavior on color {
                                    enabled: popup.visible
                                    ColorAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            background: null
                        }
                    }
                }
            }

            Separator {}

            ColumnLayout {
                enabled: Inhibit.mode !== "off"
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
                        highlighted: Inhibit.duration === 0
                        onClicked: {
                            root.range = 120;
                            Inhibit.setDuration(0);
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
                            highlighted: Inhibit.duration === modelData
                            onClicked: {
                                root.range = Math.max(120, modelData);
                                Inhibit.setDuration(modelData);
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: Inhibit.expiresAt > 0
                    spacing: 0

                    RowLayout {
                        Text {
                            Layout.fillWidth: true
                            text: root.formatDuration(countdown.minutes) + " left"
                            font.pixelSize: 12
                            color: Theme.textPrimary
                        }
                        Text {
                            readonly property double deadline: countdown.pressed ? Inhibit.now + countdown.minutes * 60000 : Inhibit.expiresAt

                            text: "Until " + Qt.formatDateTime(new Date(deadline), "hh:mm")
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                    }

                    Slider {
                        id: countdown
                        readonly property real minutes: pressed ? valueAt(position) : Inhibit.remaining

                        Layout.fillWidth: true
                        leftPadding: minimumLabel.implicitWidth + 6
                        rightPadding: maximumLabel.implicitWidth + 6
                        from: 1
                        to: root.range
                        value: Inhibit.remaining
                        stepSize: 1
                        snapMode: Controls.Slider.SnapAlways
                        live: false
                        wheelEnabled: !pressed
                        onPressedChanged: {
                            if (pressed) {
                                value = Inhibit.remaining;
                                return;
                            }
                            Inhibit.setDuration(value);
                            value = Qt.binding(() => Inhibit.remaining);
                        }
                        onMoved: {
                            if (!pressed)
                                Inhibit.setDuration(Math.ceil(value));
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
            color: control.highlighted ? Theme.textOnSelected : Theme.textPrimary
        }
        background: Rectangle {
            radius: 4
            border.width: control.visualFocus ? 1 : 0
            border.color: Theme.accent
            color: Qt.tint(control.highlighted ? Theme.selectedBackground : Theme.controlBackground, control.down ? Theme.pressedBackground : control.hovered ? Theme.hoveredBackground : "transparent")
        }
    }
}
