pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.widgets.notification

Scope {
    Variants {
        model: Quickshell.screens
        NotificationWindow {
            required property ShellScreen modelData
            screen: modelData
            output: modelData.name
            popups: NotificationService.popups
            onFinished: popup => NotificationService.remove(popup)
        }
    }
}
