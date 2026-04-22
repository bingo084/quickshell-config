pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

WrapperRectangle {
    id: root
    implicitWidth: 32
    implicitHeight: 30
    radius: 4
    color: Qt.darker("#ffffff", area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

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
                color: "#1a1a1a"
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
            source: OsInfo.logo()
        }
    }
    PopupWindow {
        id: menu
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight

        anchor {
            item: root
            // qmllint disable missing-type
            edges: Edges.Bottom | Edges.Left
            gravity: Edges.Bottom | Edges.Left
            adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
            // qmllint enable missing-type
            margins.top: 6
        }
        color: "transparent"

        WrapperRectangle {
            id: background
            radius: 8
            color: "#ffffff"
            border.color: "#dcdcdc"
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
