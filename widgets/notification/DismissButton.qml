import QtQuick
import qs.config

NotificationButton {
    id: root
    property bool expandable: false

    size: 24
    implicitHeight: size
    implicitWidth: text ? implicitContentWidth + 16 : implicitHeight
    text: expandable && (hovered || down || visualFocus) ? "Clear All" : ""
    iconName: text ? "" : "window-close-symbolic"
    icon.color: Theme.textSecondary

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
}
