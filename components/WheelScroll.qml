import QtQuick

MouseArea {
    id: root
    required property Flickable flickable
    parent: flickable
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    scrollGestureEnabled: false
    enabled: flickable.interactive && flickable.visible && flickable.contentHeight > flickable.height
    onEnabledChanged: if (!enabled)
        scroll.stop()

    onWheel: event => {
        if (event.pixelDelta.x !== 0 || event.pixelDelta.y !== 0 || event.angleDelta.y === 0) {
            scroll.stop();
            event.accepted = false;
            return;
        }
        const delta = -event.angleDelta.y / 120 * Application.styleHints.wheelScrollLines * 20;
        const start = flickable.contentY;
        const previous = scroll.running && (scroll.to - start) * delta > 0 ? scroll.to : start;
        const end = Math.max(flickable.originY, Math.min(flickable.originY + flickable.contentHeight - flickable.height, previous + delta));
        if (end === start) {
            scroll.stop();
            event.accepted = false;
            return;
        }
        flickable.cancelFlick();
        scroll.stop();
        scroll.from = start;
        scroll.to = end;
        scroll.start();
        event.accepted = true;
    }

    Connections {
        target: root.flickable
        function onMovementStarted() {
            scroll.stop();
        }
        function onContentHeightChanged() {
            scroll.stop();
        }
        function onHeightChanged() {
            scroll.stop();
        }
    }
    NumberAnimation {
        id: scroll
        target: root.flickable
        property: "contentY"
        duration: 160
        easing.type: Easing.OutCubic
    }
}
