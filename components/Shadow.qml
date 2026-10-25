pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: root
    property alias color: shadow.color
    property alias radius: shadow.radius
    property alias blur: shadow.blur
    property alias offset: shadow.offset
    readonly property real padding: Math.ceil(blur + Math.max(Math.abs(offset.x), Math.abs(offset.y)))

    Item {
        id: buffer
        x: -root.padding
        y: -root.padding
        width: root.width + 2 * root.padding
        height: root.height + 2 * root.padding
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: cutout
        }

        RectangularShadow {
            id: shadow
            x: root.padding
            y: root.padding
            width: root.width
            height: root.height
            blur: 22
            offset.y: 5
            color: Theme.shadow
        }
    }

    Item {
        id: cutout
        width: buffer.width
        height: buffer.height
        visible: false
        layer.enabled: true

        Rectangle {
            x: root.padding
            y: root.padding
            width: root.width
            height: root.height
            radius: root.radius
            color: "white"
        }
    }
}
