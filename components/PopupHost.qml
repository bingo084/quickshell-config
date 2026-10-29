pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config

PopupWindow {
    id: root
    enum Phase {
        Hidden,
        Open,
        Capturing,
        Closing
    }
    property Popup activePopup: null
    property int phase: PopupHost.Hidden
    readonly property bool opened: phase === PopupHost.Open || phase === PopupHost.Capturing
    property real center
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
    readonly property alias card: background
    readonly property Region region: Region {
        regions: [cardRegion, ...(root.activePopup?.regions ?? [])]
    }
    mask: root.region
    BackgroundEffect.blurRegion: root.phase === PopupHost.Closing ? null : root.region
    Region {
        id: cardRegion
        item: background
        radius: background.radius
    }

    onClosed: root.release()
    onPhaseChanged: {
        if (phase === PopupHost.Open || phase === PopupHost.Closing) {
            surfaceFade.to = phase === PopupHost.Open ? 1 : 0;
            surfaceFade.restart();
        }
    }

    function open(popup: Popup, anchorItem = popup.anchorItem) {
        const previous = activePopup;
        if (previous !== null && previous.anchorItem?.QsWindow.window !== anchorItem.QsWindow.window)
            root.visible = false;
        if (previous !== null && previous !== popup) {
            previous.content.parent = null;
            if (previous.overlay !== null)
                previous.overlay.parent = null;
        }
        if (popup.overlay !== null)
            popup.overlay.parent = stage;
        if (popup.anchorItem !== anchorItem)
            popup.anchorItem = anchorItem;
        activePopup = popup;
        center = anchorItem.mapToItem(root.bar, anchorItem.width / 2, 0).x;
        phase = PopupHost.Open;
        root.visible = true;
        popup.content.forceActiveFocus();
    }

    function close() {
        if (phase !== PopupHost.Open)
            return;
        surfaceFade.stop();
        contentFade.stop();
        const rects = [Qt.rect(background.x, background.y, background.width, background.height)];
        const extra = activePopup.overlay?.childrenRect;
        if (extra && extra.width > 0 && extra.height > 0)
            rects.push(extra);
        const left = Math.min(...rects.map(rect => rect.x));
        const top = Math.min(...rects.map(rect => rect.y));
        const right = Math.max(...rects.map(rect => rect.x + rect.width));
        const bottom = Math.max(...rects.map(rect => rect.y + rect.height));
        closeFrame.startOpacity = stage.opacity;
        closeFrame.x = Math.max(0, left - shadow.blur);
        closeFrame.y = Math.max(0, top - shadow.blur);
        closeFrame.width = Math.min(root.width, right + shadow.blur) - closeFrame.x;
        closeFrame.height = Math.min(root.height, bottom + shadow.blur + shadow.offset.y) - closeFrame.y;
        phase = PopupHost.Capturing;
    }

    function release() {
        phase = PopupHost.Hidden;
        root.visible = false;
        surfaceFade.stop();
        if (activePopup !== null) {
            activePopup.content.parent = null;
            if (activePopup.overlay !== null)
                activePopup.overlay.parent = null;
        }
        activePopup = null;
    }

    Connections {
        target: root.activePopup
        function onReadyChanged() {
            contentWrapper.reveal();
            Qt.callLater(background.updateGeometry);
        }
        function onPreferredWidthChanged() {
            Qt.callLater(background.updateGeometry);
        }
        function onMinimumWidthChanged() {
            Qt.callLater(background.updateGeometry);
        }
        function onMaximumWidthChanged() {
            Qt.callLater(background.updateGeometry);
        }
        function onContentMarginChanged() {
            Qt.callLater(background.updateGeometry);
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        visible: root.phase !== PopupHost.Closing
        enabled: root.phase === PopupHost.Open

        Shadow {
            id: shadow
            anchors.fill: background
            radius: background.radius
        }

        ClippingRectangle {
            id: background
            property real margin: 12
            readonly property real inset: margin + border.width

            x: Math.max(0, Math.min(root.width - width, root.center - width / 2))
            radius: Theme.popupRadius
            color: Theme.background
            border.color: Theme.border
            border.width: 1
            contentUnderBorder: true

            Behavior on implicitHeight {
                enabled: root.opened && !surfaceFade.running
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            function updateGeometry() {
                const popup = root.activePopup;
                if (!popup?.ready)
                    return;
                margin = popup.contentMargin;
                const width = popup.preferredWidth > 0 ? popup.preferredWidth : contentWrapper.implicitWidth + 2 * inset;
                implicitWidth = Math.max(popup.minimumWidth, Math.min(popup.maximumWidth, width));
                implicitHeight = contentWrapper.implicitHeight + 2 * inset;
            }

            WrapperItem {
                id: contentWrapper
                x: background.inset
                y: x
                width: background.width - 2 * x
                child: root.activePopup?.content ?? null
                onChildChanged: {
                    reveal();
                    Qt.callLater(background.updateGeometry);
                }
                onImplicitWidthChanged: Qt.callLater(background.updateGeometry)
                onImplicitHeightChanged: Qt.callLater(background.updateGeometry)

                function reveal() {
                    contentFade.stop();
                    if (!root.activePopup?.ready)
                        opacity = 0;
                    else if (root.opened)
                        contentFade.restart();
                    else
                        opacity = 1;
                }
            }
        }
    }

    Loader {
        id: closeFrame
        property real startOpacity: 1
        active: root.phase === PopupHost.Capturing || root.phase === PopupHost.Closing
        clip: true
        opacity: stage.opacity / Math.max(startOpacity, 0.001)
        sourceComponent: Item {
            ScreencopyView {
                captureSource: root.screen as QtObject
                width: root.screen.width // qmllint disable missing-property
                height: root.screen.height // qmllint disable missing-property
                x: -closeFrame.x
                y: -closeFrame.y - Math.round((root.bar.height + 4) * root.devicePixelRatio) / root.devicePixelRatio
                onHasContentChanged: {
                    if (hasContent && root.phase === PopupHost.Capturing)
                        root.phase = PopupHost.Closing;
                }
            }
        }
    }

    Timer {
        interval: 300
        running: root.phase === PopupHost.Capturing
        onTriggered: {
            console.warn("Popup closing capture timed out");
            root.release();
        }
    }

    NumberAnimation {
        id: surfaceFade
        target: stage
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
        target: contentWrapper
        property: "opacity"
        from: 0
        to: 1
        duration: 120
        easing.type: Easing.OutCubic
    }
}
