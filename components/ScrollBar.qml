import QtQuick
import QtQuick.Controls
import qs.config

ScrollBar {
    palette.mid: hovered ? Theme.scrollThumbHover : Theme.scrollThumb
    palette.dark: Theme.scrollThumbPress

    Behavior on palette.mid {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
}
