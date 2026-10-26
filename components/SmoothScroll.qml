import QtQuick

MouseArea {
    id: root
    required property Flickable flickable
    property real filterMargin: 3
    property bool filtering: false
    property real filteredY: 0
    Translate {
        id: offset
        y: root.filtering ? root.flickable.contentY - root.filteredY : 0
        Component.onCompleted: root.flickable.contentItem.transform.push(offset)
    }

    parent: flickable
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    enabled: flickable.interactive && flickable.visible && flickable.contentHeight > flickable.height
    onEnabledChanged: {
        if (!enabled) {
            scroll.stop();
            filtering = false;
        }
    }

    onWheel: event => {
        event.accepted = false;
        if (event.device.type === PointerDevice.TouchPad) {
            if (!root.filtering)
                root.filteredY = root.flickable.contentY;
            root.filtering = true;
            scroll.stop();
            return;
        }
        filtering = false;
        if (event.pixelDelta.x !== 0 || event.pixelDelta.y !== 0 || event.angleDelta.y === 0) {
            scroll.stop();
            return;
        }
        const delta = -event.angleDelta.y / 120 * Application.styleHints.wheelScrollLines * 20;
        const start = flickable.contentY;
        const base = scroll.running && (scroll.to - start) * delta > 0 ? scroll.to : start;
        const end = Math.max(flickable.originY, Math.min(flickable.originY + flickable.contentHeight - flickable.height, base + delta));
        if (end === start) {
            scroll.stop();
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
        function onContentYChanged() {
            if (!root.filtering)
                return;
            const position = root.flickable.contentY;
            const bottom = root.flickable.originY + root.flickable.contentHeight - root.flickable.height;
            if (position <= root.flickable.originY || position >= bottom)
                root.filteredY = position;
            else if (position > root.filteredY + root.filterMargin)
                root.filteredY = position - root.filterMargin;
            else if (position < root.filteredY - root.filterMargin)
                root.filteredY = position + root.filterMargin;
        }
        function onMovementStarted() {
            scroll.stop();
        }
        function onContentHeightChanged() {
            scroll.stop();
            root.filtering = false;
        }
        function onHeightChanged() {
            scroll.stop();
            root.filtering = false;
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
