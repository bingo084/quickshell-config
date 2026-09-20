pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.config
import qs.services
import qs.widgets.power

Button {
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
            command: ["systemctl", "suspend"],
            capability: "suspend"
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

    Popup {
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
                        MenuItem {
                            icon: loader.modelData.icon
                            fallbackIcon: loader.modelData.fallbackIcon || ""
                            label: loader.modelData.label
                            enabled: PowerCapabilities.canExecute(loader.modelData.capability)
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
