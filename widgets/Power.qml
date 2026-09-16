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
    property var pendingAction: null
    readonly property var actions: [
        {
            label: "Lock",
            command: ["loginctl", "lock-session"]
        },
        {
            label: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Log Out",
            command: ["niri", "msg", "action", "quit", "--skip-confirmation"],
            confirm: true
        },
        {
            label: "Reboot",
            command: ["systemctl", "reboot"],
            confirm: true
        },
        {
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

        popup.visible = false;
        Quickshell.execDetached(action.command);
    }

    component MenuButton: WrapperRectangle {
        id: button
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

        onVisibleChanged: {
            if (!visible)
                root.pendingAction = null;
        }

        Loader {
            sourceComponent: root.pendingAction === null ? menuPage : confirmationPage

            Component {
                id: menuPage

                ColumnLayout {
                    spacing: 1

                    Repeater {
                        model: root.actions

                        MenuButton {
                            required property var modelData
                            label: modelData.label
                            onTriggered: root.activate(modelData)
                        }
                    }
                }
            }

            Component {
                id: confirmationPage

                ColumnLayout {
                    spacing: 6

                    Text {
                        Layout.preferredWidth: 190
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.pendingAction === null ? "" : `Are you sure you want to ${root.pendingAction.label}?`
                    }

                    RowLayout {
                        spacing: 4

                        MenuButton {
                            label: "Cancel"
                            onTriggered: root.pendingAction = null
                        }
                        MenuButton {
                            label: root.pendingAction?.label ?? "Confirm"
                            onTriggered: root.confirm()
                        }
                    }
                }
            }
        }
    }
}
