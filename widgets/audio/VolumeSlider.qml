import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.services

Rectangle {
    id: root
    required property PwNode node
    readonly property bool ready: node?.audio != null

    Layout.fillWidth: true
    Layout.preferredHeight: 6
    radius: height / 2
    color: "#ededed"
    enabled: ready
    opacity: ready ? 1 : 0.55

    Rectangle {
        width: parent.width * (root.ready ? Math.min(root.node.audio.volume, 1) : 0)
        height: parent.height
        radius: parent.radius
        color: root.ready && root.node.audio.muted ? "#a0a0a0" : Theme.accent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => Audio.setVolume(mouse.x / root.width, root.node)
        onPositionChanged: mouse => pressed && Audio.setVolume(mouse.x / root.width, root.node)
        onWheel: wheel => {
            Audio.adjustVolume(wheel.angleDelta.y > 0 ? 0.01 : -0.01, root.node);
            wheel.accepted = true;
        }
    }
}
