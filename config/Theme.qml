pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    readonly property color barBackground: ColorService.data.surface
    readonly property bool dark: barBackground.hslLightness < 0.5
    readonly property color barTint: Qt.alpha(dark ? "#262629" : "#ffffff", dark ? 0.5 : 0.7)
    readonly property color textPrimary: ColorService.data.on_surface
    readonly property color textSecondary: ColorService.data.on_surface_variant
    readonly property color textTertiary: Qt.tint(popupBackground, Qt.alpha(textSecondary, 0.8))
    readonly property color hoveredBackground: Qt.alpha(textPrimary, 0.08)
    readonly property color pressedBackground: Qt.alpha(textPrimary, 0.12)
    readonly property color popupBackground: ColorService.data.surface_container
    readonly property color popupTint: Qt.alpha(dark ? "#262629" : "#ffffff", dark ? 0.78 : 0.80)
    readonly property color popupBorder: ColorService.data.outline_variant
    readonly property color accent: ColorService.data.primary
    readonly property color textOnAccent: ColorService.data.on_primary
    readonly property color controlBackground: ColorService.data.surface_container_high
    readonly property color selectedBackground: ColorService.data.primary_container
    readonly property color textOnSelected: ColorService.data.on_primary_container
    readonly property color meterBackground: ColorService.data.surface_container_highest
    readonly property int barItemRadius: 4
    readonly property int popupRadius: 8
    readonly property color warning: ColorService.data.warning
    readonly property color critical: ColorService.data.error

    function levelColor(level: int, normal = textPrimary): color {
        return [normal, warning, critical][level];
    }
}
