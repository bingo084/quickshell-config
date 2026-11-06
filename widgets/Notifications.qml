pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.widgets.notification

Scope {
    Binding {
        target: NotificationService
        property: "popupVisible"
        value: PopupHost.activePopup instanceof NotificationPopup
    }
    Binding {
        target: NotificationService
        property: "notificationsVisible"
        value: {
            const panel = PopupHost.activePopup as NotificationPopup;
            return panel !== null && panel.visible && !panel.showingHistory;
        }
    }
    Variants {
        model: Quickshell.screens
        NotificationWindow {
            required property ShellScreen modelData
            screen: modelData
            banners: NotificationService.banners
            onFinished: record => NotificationService.removeBanner(record)
        }
    }
}
