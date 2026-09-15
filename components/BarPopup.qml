import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    required property Item anchorItem
    property real contentMargin: 8
    default property alias content: background.child

    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight
    color: "transparent"
    anchor {
        item: anchorItem
        // qmllint disable missing-type
        edges: Edges.Bottom
        gravity: Edges.Bottom
        // qmllint enable missing-type
        margins.bottom: -4
    }

    WrapperRectangle {
        id: background
        radius: Theme.popupRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        border.width: 1
        margin: root.contentMargin
    }
}
