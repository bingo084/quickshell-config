pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
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
        menu.visible = false;
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
            menu.anchor.updateAnchor();
            // qmllint enable unresolved-type
            menu.visible = !menu.visible;
        }

        IconImage {
            implicitSize: 18
            source: OsInfo.logo()
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
            radius: Theme.popupRadius
            color: Theme.popupBackground
            border.color: Theme.popupBorder
            border.width: 1
            margin: 6

            ColumnLayout {
                id: column
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
}
