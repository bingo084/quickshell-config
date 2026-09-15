pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

WrapperRectangle {
    id: root
    radius: Theme.barItemRadius
    color: Qt.darker(Theme.barItemBackground, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

    readonly property var menuItems: [
        {
            label: "Lock",
            command: ["loginctl", "lock-session"]
        },
        {
            label: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Reboot",
            command: ["systemctl", "reboot"]
        },
        {
            label: "Power Off",
            command: ["systemctl", "poweroff"]
        }
    ]

    function run(command) {
        popup.visible = false;
        Quickshell.execDetached(command);
    }

    component MenuButton: WrapperRectangle {
        id: button
        required property string label
        required property list<string> command

        implicitWidth: 90
        implicitHeight: 30
        radius: 6
        color: buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : "transparent"

        WrapperMouseArea {
            id: buttonArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 6
            onClicked: root.run(parent.command)

            Text {
                color: Theme.textPrimary
                text: button.label
            }
        }
    }

    WrapperMouseArea {
        id: area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6
        onClicked: {
            // qmllint disable unresolved-type
            popup.anchor.updateAnchor();
            // qmllint enable unresolved-type
            popup.visible = !popup.visible;
        }

        IconImage {
            implicitSize: 18
            source: OsInfo.logo()
        }
    }

    BarPopup {
        id: popup
        anchorItem: root
        contentMargin: 6

        ColumnLayout {
            spacing: 1

            Repeater {
                model: root.menuItems

                MenuButton {
                    required property var modelData
                    label: modelData.label
                    command: modelData.command
                }
            }
        }
    }
}
