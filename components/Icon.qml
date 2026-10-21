pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.impl
import qs.config
import qs.services

Item {
    id: root
    property string name
    property url source
    property string theme
    property real size
    property real padding: size > 0 ? (size - implicitSize) / 2 : 0
    property alias color: image.color
    property bool spinning
    property bool pulsing
    property bool showBadge
    property color badgeColor: Theme.warning
    property alias status: image.status
    property real implicitSize: 18

    implicitWidth: implicitSize + 2 * padding
    implicitHeight: implicitWidth

    IconImage {
        id: image
        readonly property var resolved: IconService.resolve(root.name, root.source, root.theme)
        anchors.fill: parent
        anchors.margins: root.padding
        name: resolved.name
        source: resolved.source
        sourceSize.width: Math.max(0, Math.min(width, height))
        sourceSize.height: Math.max(0, Math.min(width, height))
        cache: name === ""
        color: Theme.textPrimary

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 1300
            loops: Animation.Infinite
            running: root.spinning
            onStopped: image.rotation = 0
        }
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
        anchors.top: image.top
        anchors.right: image.right
        width: 6
        height: 6
        radius: 3
        visible: root.showBadge
        color: root.badgeColor
        border.color: Theme.barBackground
        border.width: 1
    }
}
