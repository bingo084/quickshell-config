pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

Singleton {
    id: root
    readonly property alias popups: popupModel

    ListModel {
        id: popupModel
    }

    NotificationServer {
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            for (let i = 0; i < popupModel.count; i++) {
                const popup = popupModel.get(i).popup;
                if (popup.notification === notification) {
                    popup.refresh();
                    return;
                }
            }
            const popup = popupComponent.createObject(root, {
                notification: notification,
                output: root.focusedOutput()
            });
            popupModel.insert(0, {
                popup: popup
            });
        }
    }

    function focusedOutput(): string {
        const workspaces = NiriService.workspaces;
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (workspace.isFocused && Quickshell.screens.some(screen => screen.name === workspace.output))
                return workspace.output;
        }
        return Quickshell.screens[0]?.name ?? "";
    }

    function remove(popup: QtObject) {
        for (let i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).popup === popup) {
                popupModel.remove(i);
                popup.destroy();
                return;
            }
        }
    }

    Component {
        id: popupComponent
        Scope {
            id: popup
            required property Notification notification
            required property string output
            property date receivedAt: new Date()
            property bool closing: false
            signal refreshed

            function refresh() {
                receivedAt = new Date();
                refreshed();
            }

            RetainableLock {
                object: popup.notification
                locked: true
            }
            Connections {
                target: popup.notification
                function onClosed() {
                    popup.closing = true;
                }
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            const outputs = Quickshell.screens.map(screen => screen.name);
            for (let i = 0; i < popupModel.count; i++) {
                const popup = popupModel.get(i).popup;
                if (!outputs.includes(popup.output))
                    popup.output = root.focusedOutput();
            }
        }
    }
}
