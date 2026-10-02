pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    readonly property color barItemBackground: Colors.data.surface_container_low
    readonly property color textPrimary: Colors.data.on_surface
    readonly property color textSecondary: Colors.data.on_surface_variant
    readonly property color textTertiary: Qt.tint(popupBackground, Qt.alpha(textSecondary, 0.8))
    readonly property color hoveredBackground: Qt.tint(popupBackground, Qt.alpha(textPrimary, 0.08))
    readonly property color pressedBackground: Qt.tint(popupBackground, Qt.alpha(textPrimary, 0.12))
    readonly property color popupBackground: Colors.data.surface_container
    readonly property color popupBorder: Colors.data.outline_variant
    readonly property color accent: Colors.data.primary
    readonly property color textOnAccent: Colors.data.on_primary
    readonly property color controlBackground: Colors.data.surface_container_high
    readonly property color selectedBackground: Colors.data.primary_container
    readonly property color textOnSelected: Colors.data.on_primary_container
    readonly property color meterBackground: Colors.data.surface_container_highest
    readonly property int barItemRadius: 4
    readonly property int popupRadius: 8
    readonly property color warning: Colors.data.warning
    readonly property color critical: Colors.data.error
}
