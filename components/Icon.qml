pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.config

IconImage {
    id: root
    property color color: Theme.textPrimary
    property bool colorize: true

    implicitSize: 18
    backer.layer.enabled: root.colorize

    backer.layer.effect: MultiEffect {
        contrast: -1
        brightness: 0.5
        colorization: 1
        colorizationColor: root.color
    }
}
