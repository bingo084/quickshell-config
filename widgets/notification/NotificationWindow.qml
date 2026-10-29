pragma ComponentBehavior: Bound

import QtQuick
import QtQuick as Quick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow { // qmllint disable uncreatable-type
    id: window
    required property var popups
    required property string output
    signal finished(QtObject popup)
    readonly property real padding: 28
    readonly property bool hasPopups: {
        for (let i = 0; i < popups.count; i++) {
            if (popups.get(i).popup.output === output)
                return true;
        }
        return false;
    }

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: 38
    implicitWidth: stack.width + padding * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: hasPopups
    mask: Region {
        regions: scrollBar.size < 1 ? [scene, scrollBarRegion] : [scene]
    }
    BackgroundEffect.blurRegion: scene
    Region {
        id: scene
        regions: [cardRegions, scrollRegion]
    }

    Region {
        id: cardRegions
        regions: Array.from({
            length: cards.count
        }, (_, i) => ((cards.itemAt(i) as Loader)?.item as NotificationCard)?.region).filter(Boolean)
    }
    Region {
        id: scrollBarRegion
        item: scrollBar
    }
    Region {
        id: scrollRegion
        item: scroll
        intersection: Intersection.Intersect
    }

    Quick.Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: stack.height + window.padding * 2
        clip: true
        boundsBehavior: Quick.Flickable.StopAtBounds
        onContentYChanged: scene.changed()
        SmoothScroll {
            flickable: scroll
        }
        Controls.ScrollBar.vertical: ScrollBar {
            id: scrollBar
            viewport: scroll
            x: scroll.width - (window.padding + width) / 2
            y: window.padding
            height: Math.max(0, scroll.height - window.padding * 2)
        }

        Column {
            id: stack
            x: window.padding
            y: window.padding
            width: 360
            spacing: 10
            Repeater {
                id: cards
                model: window.popups
                Loader {
                    id: loader
                    required property var popup
                    active: popup.output === window.output
                    visible: active
                    width: stack.width
                    sourceComponent: NotificationCard {
                        popup: loader.popup
                        onFinished: window.finished(loader.popup)
                    }
                    onHeightChanged: stack.forceLayout()
                }
            }
        }
    }
}
