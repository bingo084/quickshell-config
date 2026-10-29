pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.config

Item {
    id: root
    property real sideWidth
    readonly property real artworkHeight: 176
    property var entry: null
    property var switchRequest: null
    property Page current: first
    readonly property Page other: current === first ? second : first
    property int movement: 1
    property real progress: 1
    signal activated(var player)

    implicitHeight: Math.max(first.implicitHeight, second.implicitHeight)
    clip: true

    onEntryChanged: Qt.callLater(update)

    function prepareSwitch(key, direction: int) {
        switchRequest = {
            key,
            direction
        };
    }

    function update() {
        if (entry?.loading)
            return;
        if (!entry) {
            switchRequest = null;
            slide.stop();
            progress = 1;
            first.entry = null;
            second.entry = null;
            return;
        }
        if (slide.running)
            return;
        if (current.entry?.key === entry.key) {
            current.entry = entry;
            switchRequest = null;
            return;
        }
        other.entry = entry;
        Qt.callLater(activate);
    }

    function activate() {
        if (slide.running || !entry || other.entry !== entry || !other.ready)
            return;
        const previous = current;
        current = other;
        const direction = switchRequest?.key === entry.key ? switchRequest.direction : 0;
        switchRequest = null;
        if (previous.entry && direction !== 0) {
            movement = direction;
            progress = 0;
            slide.restart();
        } else {
            progress = 1;
            previous.entry = null;
        }
    }

    component Page: ColumnLayout {
        id: page
        property var entry: null
        readonly property bool ready: !entry || entry.source.toString() === "" || cover.status === Image.Ready || cover.status === Image.Error

        width: root.width
        x: page === root.current ? root.movement * root.width * (1 - root.progress) : -root.movement * root.width * root.progress
        spacing: 8
        onReadyChanged: root.activate()

        Item {
            Layout.fillWidth: true
            implicitHeight: root.artworkHeight

            ClippingRectangle {
                anchors.centerIn: parent
                width: cover.paintedWidth > 0 ? cover.paintedWidth : root.artworkHeight
                height: cover.paintedHeight > 0 ? cover.paintedHeight : root.artworkHeight
                radius: 8
                color: Theme.controlBackground
                scale: page.entry?.playing ? 1 : 0.9

                Behavior on scale {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Image {
                    id: cover
                    readonly property real dpr: Window.window?.devicePixelRatio ?? 1
                    anchors.centerIn: parent
                    width: Math.max(0, root.width - 2 * root.sideWidth)
                    height: root.artworkHeight
                    source: page.entry?.source ?? ""
                    sourceSize: Qt.size(Math.ceil(width * dpr), Math.ceil(height * dpr))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    retainWhileLoading: true
                }

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status === Image.Null || cover.status === Image.Error
                    name: "audio-x-generic-symbolic"
                    implicitSize: 48
                    color: Theme.textTertiary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: page === root.current && root.progress === 1 && (page.entry?.canActivate ?? false)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(page.entry.key)
                }
            }
        }

        ColumnLayout {
            spacing: 5

            Text {
                Layout.fillWidth: true
                text: page.entry?.provider ?? ""
                font.pixelSize: 10
                color: Theme.textTertiary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                id: title
                Layout.fillWidth: true
                text: page.entry?.title ?? ""
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.textPrimary

                Tooltip {
                    anchorItem: title
                    enabled: title.truncated
                    text: title.text
                }
            }

            Text {
                id: subtitle
                Layout.fillWidth: true
                text: page.entry?.subtitle ?? ""
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                color: Theme.textSecondary

                Tooltip {
                    anchorItem: subtitle
                    enabled: subtitle.truncated
                    text: subtitle.text
                }
            }
        }
    }

    Page {
        id: first
    }

    Page {
        id: second
    }

    NumberAnimation {
        id: slide
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: 260
        easing.type: Easing.InOutCubic
        onFinished: {
            root.other.entry = null;
            root.update();
        }
    }
}
