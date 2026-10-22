import QtQuick
import QtQuick.Controls
import qs.config

ScrollBar {
    palette.mid: Qt.alpha(Theme.textPrimary, hovered ? 0.55 : 0.35)
    palette.dark: Qt.alpha(Theme.textPrimary, 0.7)

    Behavior on palette.mid {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
}
