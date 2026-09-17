pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.widgets.power

BarButton {
    id: root
    required property ShellScreen screen
    property var pendingAction: null
    readonly property var actions: [
        {
            icon: "system-lock-screen-symbolic",
            label: "Lock",
            command: ["loginctl", "lock-session"]
        },
        {
            icon: "system-suspend-symbolic",
            label: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            icon: "system-log-out-symbolic",
            label: "Log Out",
            command: ["niri", "msg", "action", "quit", "--skip-confirmation"],
            confirm: true
        },
        {
            icon: "system-reboot-symbolic",
            label: "Reboot",
            command: ["systemctl", "reboot"],
            confirm: true
        },
        {
            icon: "system-shutdown-symbolic",
            label: "Power Off",
            command: ["systemctl", "poweroff"],
            confirm: true
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

    function activate(action) {
        if (action.confirm) {
            popup.visible = false;
            pendingAction = action;
        } else {
            popup.visible = false;
            Quickshell.execDetached(action.command);
        }
    }

    function confirm() {
        const action = pendingAction;
        if (action === null)
            return;

        pendingAction = null;
        Quickshell.execDetached(action.command);
    }

    component MenuButton: WrapperRectangle {
        id: button
        required property string icon
        required property string label
        signal triggered

        implicitWidth: 90
        implicitHeight: 30
        radius: 6
        color: buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : "transparent"

        WrapperMouseArea {
            id: buttonArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 6
            onClicked: button.triggered()
            RowLayout {
                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(button.icon, true)
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    text: button.label
                }
            }
        }
    }

    BarPopup {
        id: popup
        anchorItem: root
        contentMargin: 6

        onVisibleChanged: {
            if (!visible)
                root.pendingAction = null;
        }

        ColumnLayout {
            spacing: 1

            Repeater {
                model: root.actions

                MenuButton {
                    required property var modelData
                    onTriggered: root.activate(modelData)
                }
            }
        }
    }
    PowerDialog {
        screen: root.screen
        actionLabel: root.pendingAction?.label ?? ""
        visible: root.pendingAction !== null
        onCanceled: root.pendingAction = null
        onConfirmed: root.confirm()
    }
}
