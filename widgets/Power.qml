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
    readonly property var menuEntries: [
        {
            icon: "system-lock-screen-symbolic",
            label: "Lock",
            command: ["loginctl", "lock-session"]
        },
        {
            separator: true
        },
        {
            icon: "system-suspend-symbolic",
            label: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            icon: "system-hibernate-symbolic",
            fallbackIcon: "drive-harddisk-system-symbolic",
            label: "Hibernate",
            command: ["systemctl", "hibernate"],
            capability: "hibernate"
        },
        {
            separator: true
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
        popup.visible = !popup.visible;
        if (popup.visible) {
            PowerCapabilities.refresh();
        }
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
        property string fallbackIcon
        readonly property string resolvedIcon: fallbackIcon !== "" && !Quickshell.hasThemeIcon(icon) ? fallbackIcon : icon
        required property string label
        signal triggered

        implicitWidth: 90
        implicitHeight: 30
        radius: 6
        color: buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : "transparent"
        opacity: enabled ? 1 : 0.5

        WrapperMouseArea {
            id: buttonArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 6
            onClicked: button.triggered()
            RowLayout {
                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(button.resolvedIcon, true)
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
                model: root.menuEntries

                Loader {
                    id: loader
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.topMargin: modelData.separator ? 1 : 0
                    Layout.bottomMargin: modelData.separator ? 1 : 0
                    sourceComponent: modelData.separator ? separator : actionButton

                    Component {
                        id: separator
                        Rectangle {
                            implicitHeight: 1
                            color: Theme.popupBorder
                        }
                    }
                    Component {
                        id: actionButton
                        MenuButton {
                            icon: loader.modelData.icon
                            fallbackIcon: loader.modelData.fallbackIcon || ""
                            label: loader.modelData.label
                            enabled: loader.modelData.capability !== "hibernate" || PowerCapabilities.hibernateStatus === "yes"
                            onTriggered: root.activate(loader.modelData)
                        }
                    }
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
