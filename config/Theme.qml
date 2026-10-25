pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    readonly property bool dark: Qt.color(ColorService.data.surface).hslLightness < 0.5

    readonly property color textPrimary: dark ? "#eeeeef" : "#252527"
    readonly property color textSecondary: dark ? "#b9b9bf" : "#626269"
    readonly property color textTertiary: dark ? "#9898a0" : "#76767e"

    readonly property color accent: ColorService.data.primary
    readonly property color textOnAccent: ColorService.data.on_primary
    readonly property color warning: ColorService.data.warning
    readonly property color critical: ColorService.data.error

    readonly property color background: Qt.alpha(dark ? "#262629" : "#ffffff", 0.8)

    readonly property color border: Qt.alpha(textPrimary, dark ? 0.16 : 0.13)
    readonly property color separator: Qt.alpha(textPrimary, 0.11)

    readonly property color cardBackground: Qt.alpha("#ffffff", dark ? 0.05 : 0.4)
    readonly property color cardBorder: Qt.alpha(textPrimary, dark ? 0.06 : 0.055)

    readonly property color controlBackground: Qt.alpha(textPrimary, 0.055)
    readonly property color selectedBackground: Qt.alpha("#ffffff", dark ? 0.13 : 0.95)
    readonly property color selectedShadow: Qt.alpha("#000000", 0.18)

    readonly property color hoverOverlay: Qt.alpha(textPrimary, 0.10)
    readonly property color pressOverlay: Qt.alpha(textPrimary, 0.12)

    readonly property color trackBackground: Qt.alpha(textPrimary, 0.12)
    readonly property color handleBackground: "#ffffff"
    readonly property color handleBorder: Qt.alpha("#000000", 0.15)

    readonly property color scrollThumb: Qt.alpha(textPrimary, 0.35)
    readonly property color scrollThumbHover: Qt.alpha(textPrimary, 0.55)
    readonly property color scrollThumbPress: Qt.alpha(textPrimary, 0.7)

    readonly property color shadow: Qt.alpha("#000000", dark ? 0.33 : 0.12)
    readonly property color scrim: "#66000000"

    readonly property int barItemRadius: 4
    readonly property int popupRadius: 8

    function levelColor(level: int, normal = textPrimary): color {
        return [normal, warning, critical][level];
    }
}
