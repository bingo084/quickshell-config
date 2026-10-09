import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    property Item anchorItem
    property alias text: label.text
    property bool active
    property int delay: 500

    implicitWidth: Math.min(Math.ceil(background.implicitWidth), 400)
    implicitHeight: background.implicitHeight
    color: "transparent"
    // qmllint disable missing-property unresolved-type unqualified
    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.bottom: -4
    }
    // qmllint enable missing-property unresolved-type unqualified
    mask: Region {}

    onActiveChanged: {
        if (!active)
            visible = false;
    }

    Timer {
        interval: root.delay
        running: root.active
        onTriggered: root.visible = true
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
