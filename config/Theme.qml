pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color barItemBackground: "#ffffff"
    readonly property color textPrimary: "#1a1a1a"
    readonly property color textSecondary: "#777777"
    readonly property color hoveredBackground: Qt.tint(popupBackground, Qt.alpha(textPrimary, 0.08))
    readonly property color pressedBackground: Qt.tint(popupBackground, Qt.alpha(textPrimary, 0.12))
    readonly property color popupBackground: "#ffffff"
    readonly property color popupBorder: "#dcdcdc"
    readonly property color accent: "#007aff"
    readonly property color textOnAccent: "#ffffff"
    readonly property int barItemRadius: 4
    readonly property int popupRadius: 8
    readonly property color meterBackground: "#dedede"
    readonly property color warning: "#c77700"
    readonly property color critical: "#d93025"
}
