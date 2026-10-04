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
            popup.visible = !popup.visible;
        } else {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
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
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 6
                color: Qt.tint(Theme.meterBackground, Theme.hoveredBackground)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0
                    Repeater {
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
                            }
                            background: Rectangle {
                                radius: 4
                                border.width: modeButton.checked ? 1 : 0
                                border.color: modeButton.modelData === "off" ? Theme.popupBorder : Qt.alpha(modeButton.modeColor, 0.4)
                                color: {
                                    if (!modeButton.checked)
                                        return "transparent";
                                    return modeButton.modelData === "off" ? Theme.popupBackground : Qt.tint(Theme.popupBackground, Qt.alpha(modeButton.modeColor, 0.4));
                                }
                            }
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.popupBorder
            }
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
                            readonly property double deadline: dragArea.pressed ? Inhibit.now + countdown.minutes * 60000 : Inhibit.expiresAt
                            text: "Until " + Qt.formatDateTime(new Date(deadline), "hh:mm")
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                    }
                    Item {
                        id: countdown
                        Layout.fillWidth: true
                        implicitHeight: 24
                        property int preview: 0
                        readonly property real maximum: root.range
                        readonly property real minutes: dragArea.pressed ? preview : Inhibit.remaining
                        readonly property real position: Math.min(1, minutes / maximum)

                        function previewAt(x: real) {
                            preview = Math.max(1, Math.min(maximum, Math.round((x - track.x) / track.width * maximum)));
                        }

                        Text {
                            id: minimumLabel
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: dragArea.pressed
                            text: "1m"
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                        Text {
                            id: maximumLabel
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: dragArea.pressed
                            text: root.formatDuration(countdown.maximum)
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                        Rectangle {
                            id: track
                            x: minimumLabel.implicitWidth + 12
                            width: parent.width - x - maximumLabel.implicitWidth - 12
                            height: 6
                            anchors.verticalCenter: parent.verticalCenter
                            radius: height / 2
                            color: Theme.meterBackground
                            Rectangle {
                                width: countdown.position * track.width
                                height: parent.height
                                radius: parent.radius
                                color: Theme.accent
                            }
                        }
                        Rectangle {
                            x: track.x + countdown.position * track.width - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            radius: 6
                            color: Theme.accent
                        }
                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onWheel: wheel => {
                                const change = Math.round(wheel.angleDelta.y / 120 * 5);
                                if (pressed || change === 0)
                                    return;
                                const minutes = Math.max(1, Math.min(countdown.maximum, Math.ceil(Inhibit.remaining) + change));
                                Inhibit.setDuration(minutes);
                            }
                            onPressed: mouse => countdown.previewAt(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    countdown.previewAt(mouse.x);
                            }
                            onReleased: Inhibit.setDuration(countdown.preview)
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
