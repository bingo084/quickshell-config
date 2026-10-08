pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.config
import qs.services

IconImage {
    id: root
    property string name
    property color color: Theme.textPrimary
    property bool colorize: true

    implicitSize: 18
    source: Icons.source(root.name)

    backer.layer.enabled: root.colorize

    backer.layer.effect: MultiEffect {
        contrast: -1
        brightness: 0.5
        colorization: 1
        colorizationColor: root.color
    }
}
