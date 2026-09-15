pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

BarButton {
    id: root
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

    onClicked: {
        // qmllint disable unresolved-type
        popup.anchor.updateAnchor();
        // qmllint enable unresolved-type
        popup.visible = !popup.visible;
    }

    content: IconImage {
        implicitSize: 18
        source: OsInfo.logo()
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
            onClicked: {
                popup.visible = false;
                Quickshell.execDetached(button.command);
            }

            Text {
                color: Theme.textPrimary
                text: button.label
            }
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
