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
    property bool spinning
    property bool pulsing
    property bool showBadge
    property color badgeColor: Theme.warning

    implicitSize: 18
    source: Icons.source(root.name)

    backer.layer.enabled: root.colorize

    backer.layer.effect: MultiEffect {
        contrast: -1
        brightness: 0.5
        colorization: 1
        colorizationColor: root.color
    }

    NumberAnimation on backer.rotation {
        from: 0
        to: 360
        duration: 1300
        loops: Animation.Infinite
        running: root.spinning
        onStopped: root.backer.rotation = 0
    }

    SequentialAnimation on opacity {
        running: root.pulsing
        loops: Animation.Infinite
        NumberAnimation {
            from: 1
            to: 0.25
            duration: 800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: 0.25
            to: 1
            duration: 800
            easing.type: Easing.InOutSine
        }
        onStopped: root.opacity = 1
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        width: 6
        height: 6
        radius: 3
        visible: root.showBadge
        color: root.badgeColor
        border.color: Theme.barBackground
        border.width: 1
    }
}
