pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    readonly property color barBackground: ColorService.data.surface
    readonly property bool dark: barBackground.hslLightness < 0.5
    readonly property color barTint: Qt.alpha(dark ? "#262629" : "#ffffff", 0.7)
    readonly property color textPrimary: dark ? "#eeeeef" : "#252527"
    readonly property color textSecondary: dark ? "#b9b9bf" : "#626269"
    readonly property color textTertiary: dark ? "#9898a0" : "#76767e"
    readonly property color hoveredBackground: Qt.alpha(textPrimary, 0.06)
    readonly property color pressedBackground: Qt.alpha(textPrimary, 0.12)
    readonly property color popupBackground: dark ? "#242427" : "#ffffff"
    readonly property color popupTint: Qt.alpha(dark ? "#262629" : "#ffffff", 0.8)
    readonly property color popupBorder: Qt.alpha(textPrimary, dark ? 0.16 : 0.13)
    readonly property color cardBackground: Qt.alpha("#ffffff", dark ? 0.05 : 0.4)
    readonly property color cardBorder: Qt.alpha(textPrimary, dark ? 0.06 : 0.055)
    readonly property color accent: ColorService.data.primary
    readonly property color textOnAccent: ColorService.data.on_primary
    readonly property color controlBackground: Qt.alpha(textPrimary, dark ? 0.10 : 0.055)
    readonly property color selectedBackground: Qt.alpha("#ffffff", dark ? 0.13 : 0.8)
    readonly property color textOnSelected: accent
    readonly property color meterBackground: Qt.alpha(textPrimary, 0.12)
    readonly property int barItemRadius: 4
    readonly property int popupRadius: 8
    readonly property color warning: ColorService.data.warning
    readonly property color critical: ColorService.data.error

    function levelColor(level: int, normal = textPrimary): color {
        return [normal, warning, critical][level];
    }
}
