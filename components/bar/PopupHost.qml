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
    implicitHeight: background.implicitHeight
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

    function position(): real {
        // Coordinate mapping must update when the button or its parents move.
        anchorTransform.transform;
        if (activePopup === null)
            return 0;
        const item = activePopup.anchorItem;
        const center = item.mapToItem(root.bar, item.width / 2, 0).x;
        return Math.max(0, Math.min(root.width - background.width, center - background.width / 2));
    }

    Behavior on implicitHeight {
        enabled: root.opened
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    TransformWatcher {
        id: anchorTransform
        a: root.bar
        b: root.activePopup?.anchorItem ?? null
    }

    WrapperRectangle {
        id: background
        x: root.position()
        child: root.activePopup?.content ?? null
        implicitWidth: (root.activePopup?.contentWidth ?? 0) + 2 * (margin + border.width)
        radius: Theme.popupRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        border.width: 1
        margin: root.activePopup?.contentMargin ?? 12
        opacity: 0
        enabled: root.opened

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
