pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import qs.components
import qs.config

Item {
    id: root
    required property MprisPlayer player
    required property bool active
    property real inset
    property color color: Theme.accent
    readonly property real thinHeight: 3
    readonly property bool hasTimeline: player !== null && player.positionSupported && player.lengthSupported && player.length > 0
    readonly property bool expanded: active && hasTimeline && (hover.hovered || seek.pressed || seek.visualFocus)
    property real expansion: expanded ? 1 : 0
    readonly property rect collapsedRect: Qt.rect(-seek.handle.width / 2, height - seek.height / 2 - thinHeight / 2, width + seek.handle.width, seek.height)
    readonly property rect expandedRect: Qt.rect(elapsed.x + elapsed.width + 8, 4, total.x - elapsed.x - elapsed.width - 16, seek.height)

    implicitHeight: seek.implicitHeight + inset
    visible: hasTimeline
    onActiveChanged: {
        if (active)
            player?.positionChanged();
    }

    function formatTime(seconds: real): string {
        const value = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(value / 60);
        const remainder = String(value % 60).padStart(2, "0");
        return minutes < 60 ? `${minutes}:${remainder}` : `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}:${remainder}`;
    }

    function interpolate(start: real, end: real): real {
        return start + (end - start) * expansion;
    }

    Behavior on expansion {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hover
    }

    FrameAnimation {
        running: root.active && root.hasTimeline && root.player.isPlaying && !seek.pressed
        onTriggered: root.player.positionChanged()
    }

    Text {
        id: elapsed
        anchors.left: parent.left
        anchors.leftMargin: root.inset
        anchors.verticalCenter: seek.verticalCenter
        text: root.formatTime(seek.value)
        font.pixelSize: 11
        color: Theme.textSecondary
        opacity: root.expansion
    }

    Slider {
        id: seek
        x: root.interpolate(root.collapsedRect.x, root.expandedRect.x)
        y: root.interpolate(root.collapsedRect.y, root.expandedRect.y)
        width: root.interpolate(root.collapsedRect.width, root.expandedRect.width)
        to: root.hasTimeline ? root.player.length : 1
        value: Math.min(to, root.player?.position ?? 0)
        enabled: root.hasTimeline && root.player.canSeek
        palette.highlight: root.color
        wheelEnabled: false
        trackHeight: root.interpolate(root.thinHeight, 6)
        handleOpacity: root.expansion
        onMoved: root.player.position = value
    }

    Text {
        id: total
        anchors.right: parent.right
        anchors.rightMargin: root.inset
        anchors.verticalCenter: seek.verticalCenter
        text: root.formatTime(root.player?.length ?? 0)
        font.pixelSize: 11
        color: Theme.textSecondary
        opacity: root.expansion
    }
}
