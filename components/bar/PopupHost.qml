pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.config

PopupWindow {
    id: root
    property Popup activePopup: null
    property bool opened: false
    readonly property Item bar: activePopup?.anchorItem.QsWindow.contentItem ?? null

    grabFocus: true
    implicitWidth: root.bar?.width ?? 0
    implicitHeight: Math.max(0, (root.screen?.height ?? 0) - (root.bar?.height ?? 0) - 4)
    color: "transparent"
    anchor {
        item: root.bar
        // qmllint disable missing-type
        edges: Edges.Bottom
        gravity: Edges.Bottom
        // qmllint enable missing-type
        margins.bottom: -4
    }
    mask: Region {
        item: background
    }

    onClosed: root.release()
    onOpenedChanged: {
        backgroundFade.to = opened ? 1 : 0;
        backgroundFade.restart();
    }

    function open(popup: Popup) {
        const previous = activePopup;
        background.forceActiveFocus();
        if (previous !== null && previous.anchorItem.QsWindow.window !== popup.anchorItem.QsWindow.window)
            root.visible = false;
        if (previous !== null && previous !== popup)
            previous.content.parent = null;
        activePopup = popup;
        const center = popup.anchorItem.mapToItem(root.bar, popup.anchorItem.width / 2, 0).x;
        background.x = Math.max(0, Math.min(root.bar.width - background.width, center - background.width / 2));
        opened = true;
        root.visible = true;
    }

    function close() {
        opened = false;
    }

    function release() {
        opened = false;
        root.visible = false;
        backgroundFade.stop();
        if (activePopup !== null)
            activePopup.content.parent = null;
        activePopup = null;
    }

    Rectangle {
        id: background
        readonly property real margin: root.activePopup?.contentMargin ?? 12

        implicitWidth: (root.activePopup?.contentWidth ?? 0) + 2 * (margin + border.width)
        implicitHeight: contentWrapper.implicitHeight + 2 * (margin + border.width)
        radius: Theme.popupRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        border.width: 1
        clip: true
        opacity: 0
        enabled: root.opened

        Behavior on implicitHeight {
            enabled: root.opened
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        WrapperItem {
            id: contentWrapper
            x: background.margin + background.border.width
            y: x
            width: background.width - 2 * x
            child: root.activePopup?.content ?? null

            onChildChanged: {
                contentFade.stop();
                contentFade.target = child;
                if (child === null)
                    return;
                if (root.opened || root.visible)
                    contentFade.restart();
                else
                    child.opacity = 1;
            }
        }
    }

    NumberAnimation {
        id: backgroundFade
        target: background
        property: "opacity"
        duration: 120
        easing.type: Easing.OutCubic
        onFinished: {
            if (!root.opened)
                root.release();
        }
    }

    NumberAnimation {
        id: contentFade
        property: "opacity"
        from: 0
        to: 1
        duration: 120
        easing.type: Easing.OutCubic
    }
}
