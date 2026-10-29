pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root
    property url source
    property alias sourceSize: first.sourceSize
    property alias sourceClipRect: first.sourceClipRect
    property alias fillMode: first.fillMode
    property real progress: 1
    readonly property bool ready: {
        const url = source.toString();
        if (url === "")
            return false;
        const image = current.source.toString() === url ? current : other;
        return image.source.toString() === url && image.status === Image.Ready;
    }

    property Image current: first
    readonly property Image other: current === first ? second : first

    onSourceChanged: Qt.callLater(load)

    function load() {
        if (source.toString() === "") {
            fade.stop();
            progress = 1;
            first.source = "";
            second.source = "";
            return;
        }
        if (fade.running || current.source.toString() === source.toString())
            return;
        const image = other;
        image.source = source;
        loaded(image);
    }

    function loaded(image: Image) {
        if (image !== other || image.source.toString() !== source.toString())
            return;
        if (image.status === Image.Error) {
            current.source = "";
            return;
        }
        if (image.status !== Image.Ready)
            return;
        const previous = current;
        current = image;
        if (previous.status === Image.Ready) {
            progress = 0;
            fade.restart();
        } else {
            progress = 1;
        }
    }

    component Layer: Image {
        id: buffer
        anchors.fill: parent
        z: root.current === buffer ? 0 : 1
        opacity: root.current === buffer ? 1 : 1 - root.progress
        asynchronous: true
        retainWhileLoading: true
        onStatusChanged: root.loaded(buffer)
    }

    Layer {
        id: first
    }

    Layer {
        id: second
        sourceSize: first.sourceSize
        sourceClipRect: first.sourceClipRect
        fillMode: first.fillMode
    }

    NumberAnimation {
        id: fade
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutSine
        onFinished: root.load()
    }
}
