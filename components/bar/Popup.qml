import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    required property Item anchorItem
    property real contentMargin: 8
    property real contentWidth: content.implicitWidth
    default property alias content: background.child

    grabFocus: true
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight
    color: "transparent"

    Behavior on implicitHeight {
        enabled: root.visible
        NumberAnimation {
            duration: 1
            easing.type: Easing.OutCubic
        }
    }

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
        implicitWidth: root.contentWidth + 2 * (root.contentMargin + border.width)
        radius: Theme.popupRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        border.width: 1
        margin: root.contentMargin

        palette {
            window: Theme.popupBackground
            windowText: Theme.textPrimary
            base: Theme.controlBackground
            text: Theme.textPrimary
            button: Theme.controlBackground
            buttonText: Theme.textPrimary
            highlight: Theme.accent
            highlightedText: Theme.textOnAccent
            mid: Theme.popupBorder
            dark: Theme.textSecondary
        }
    }

    Connections {
        target: root

        function onVisibleChanged() {
            if (root.visible)
                PopupManager.activate(root);
            else
                PopupManager.deactivate(root);
        }
    }
}
