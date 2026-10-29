pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: root
    property url source
    property bool playing: true
    property real phase: 0
    readonly property int sampleSize: 8
    readonly property bool active: visible && playing && base.ready

    opacity: Theme.dark ? 0.65 : 0.55

    Timer {
        interval: 33
        repeat: true
        running: root.active
        onTriggered: root.phase += 0.025
    }

    Item {
        id: mosaic
        anchors.fill: parent
        layer.enabled: true
        layer.textureSize: Qt.size(192, 192)
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            brightness: 0.4
            blurEnabled: true
            blur: 1
            blurMultiplier: 0.5
        }

        CoverImage {
            id: base
            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(root.sampleSize, root.sampleSize)
            fillMode: Image.PreserveAspectCrop
        }

        Repeater {
            model: 4
            CoverImage {
                required property int index
                readonly property real tileSize: root.sampleSize / 2
                readonly property real angle: root.phase + index * 1.7
                width: Math.max(mosaic.width, mosaic.height) * 1.15
                height: width
                x: mosaic.width * (index % 2 ? 0.72 : 0.28) - width / 2 + Math.sin(angle * 0.8) * mosaic.width * 0.18
                y: mosaic.height * (index < 2 ? 0.28 : 0.72) - height / 2 + Math.cos(angle * 0.65) * mosaic.height * 0.18
                rotation: index * 90 + Math.sin(angle * 0.4) * 35
                source: root.source
                sourceSize: Qt.size(root.sampleSize, root.sampleSize)
                sourceClipRect: Qt.rect(index % 2 * tileSize, Math.floor(index / 2) * tileSize, tileSize, tileSize)
                fillMode: Image.PreserveAspectCrop
                opacity: 0.65
                layer.enabled: true
                layer.textureSize: Qt.size(8, 8)
            }
        }
    }
}
