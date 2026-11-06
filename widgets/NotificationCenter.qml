import QtQuick
import qs.components
import qs.config
import qs.services
import qs.widgets.notification

BarButton {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationService.quiet = !NotificationService.quiet;
        else
            popup.toggle();
    }

    content: Icon {
        size: 18
        implicitSize: 16
        name: NotificationService.quiet ? "notification-disabled-symbolic" : "notification-symbolic"
        showBadge: NotificationService.unreadCount > 0
        badgeColor: Theme.accent
    }

    NotificationPopup {
        id: popup
        anchorItem: root
    }
}
