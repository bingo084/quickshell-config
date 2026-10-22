pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    property Popup activePopup: null
    property bool opened: false
    property bool frozen: false
    readonly property Item bar: activePopup?.anchorItem?.QsWindow.contentItem ?? null

    grabFocus: true
    implicitWidth: root.bar?.width ?? 0
    implicitHeight: Math.max(0, (root.screen?.height ?? 0) - (root.bar?.height ?? 0) - 4) // qmllint disable missing-property redundant-optional-chaining
    color: "transparent"
    // qmllint disable missing-property unresolved-type unqualified
    anchor {
        item: root.bar
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.bottom: -4
    }
    // qmllint enable missing-property unresolved-type unqualified
    mask: Region {
        item: background
    }
    BackgroundEffect.blurRegion: root.frozen ? null : blurRegion
    Region {
        id: blurRegion
        item: background
        radius: background.radius
    }

    onClosed: root.release()
    onOpenedChanged: {
        backgroundFade.to = opened ? 1 : 0;
        backgroundFade.restart();
    }

    function open(popup: Popup, anchorItem = popup.anchorItem) {
        captureTimeout.stop();
        closeFrame.active = false;
        frozen = false;
        const previous = activePopup;
        background.forceActiveFocus();
        if (previous !== null && previous.anchorItem?.QsWindow.window !== anchorItem.QsWindow.window)
            root.visible = false;
        if (previous !== null && previous !== popup)
            previous.content.parent = null;
        if (popup.anchorItem !== anchorItem)
            popup.anchorItem = anchorItem;
        activePopup = popup;
        const center = anchorItem.mapToItem(root.bar, anchorItem.width / 2, 0).x;
        background.x = Math.max(0, Math.min(root.bar.width - background.width, center - background.width / 2));
        opened = true;
        root.visible = true;
    }

    function close() {
        if (!opened || closeFrame.active)
            return;
        backgroundFade.stop();
        contentFade.stop();
        closeFrame.startOpacity = background.opacity;
        closeFrame.x = Math.max(0, background.x - shadow.blur);
        closeFrame.width = Math.min(root.width, background.x + background.width + shadow.blur) - closeFrame.x;
        closeFrame.height = Math.min(root.height, background.height + shadow.blur + shadow.offset.y);
        closeFrame.active = true;
        captureTimeout.restart();
    }

    function release() {
        captureTimeout.stop();
        closeFrame.active = false;
        frozen = false;
        opened = false;
        root.visible = false;
        backgroundFade.stop();
        if (activePopup !== null)
            activePopup.content.parent = null;
        activePopup = null;
    }

    RectangularShadow {
        id: shadow
        anchors.fill: background
        radius: background.radius
        blur: 22
        offset.y: 5
        color: Qt.alpha("#000000", Theme.dark ? 0.33 : 0.12)
        opacity: background.opacity
        visible: !root.frozen
    }

    Rectangle {
        id: background
        readonly property real margin: root.activePopup?.contentMargin ?? 12

        implicitWidth: (root.activePopup?.contentWidth ?? 0) + 2 * (margin + border.width)
        implicitHeight: contentWrapper.implicitHeight + 2 * (margin + border.width)
        radius: Theme.popupRadius
        color: Theme.popupTint
        border.color: Qt.alpha(Theme.dark ? "#ffffff" : "#000000", Theme.dark ? 0.16 : 0.10)
        border.width: 1
        clip: true
        opacity: 0
        visible: !root.frozen
        enabled: root.opened && !closeFrame.active

        Behavior on implicitHeight {
            enabled: root.opened && !backgroundFade.running
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

    Loader {
        id: closeFrame
        property real startOpacity: 1
        active: false
        clip: true
        opacity: background.opacity / Math.max(startOpacity, 0.001)
        sourceComponent: Item {
            ScreencopyView {
                captureSource: root.screen as QtObject
                width: root.screen.width // qmllint disable missing-property
                height: root.screen.height // qmllint disable missing-property
                x: -closeFrame.x
                y: -Math.round((root.bar.height + 4) * root.devicePixelRatio) / root.devicePixelRatio
                onHasContentChanged: {
                    if (!hasContent)
                        return;
                    captureTimeout.stop();
                    root.frozen = true;
                    root.opened = false;
                }
            }
        }
    }

    Timer {
        id: captureTimeout
        interval: 300
        onTriggered: {
            console.warn("Popup closing capture timed out");
            root.release();
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
