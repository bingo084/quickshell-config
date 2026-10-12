import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    property Item anchorItem
    property alias text: label.text
    property alias cursorShape: hover.cursorShape
    property bool enabled: true
    property bool atCursor
    readonly property bool hovered: hover.hovered
    readonly property bool active: enabled && hovered
    property int delay: 500

    implicitWidth: Math.min(Math.ceil(background.implicitWidth), 400)
    implicitHeight: background.implicitHeight
    color: "transparent"
    // qmllint disable missing-property unresolved-type unqualified
    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.bottom: root.atCursor ? -16 : -4
    }
    // qmllint enable missing-property unresolved-type unqualified
    mask: Region {}

    onActiveChanged: {
        if (!active)
            visible = false;
    }

    HoverHandler {
        id: hover
        parent: root.anchorItem
        enabled: root.anchorItem?.enabled ?? false
    }

    Timer {
        interval: root.delay
        running: root.active
        onTriggered: {
            // qmllint disable missing-property
            root.anchor.rect = root.atCursor ? Qt.rect(hover.point.position.x, hover.point.position.y, 1, 1) : Qt.rect(0, 0, root.anchorItem.width, root.anchorItem.height);
            // qmllint enable missing-property
            root.visible = true;
        }
    }

    WrapperRectangle {
        id: background
        width: root.width
        margin: 6
        radius: Theme.barItemRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        border.width: 1

        Text {
            id: label
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Theme.textPrimary
        }
    }
}
