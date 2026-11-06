pragma ComponentBehavior: Bound

import QtQuick
import QtQuick as Quick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow { // qmllint disable uncreatable-type
    id: window
    required property var banners
    readonly property string output: screen.name // qmllint disable missing-property
    signal finished(QtObject record)
    readonly property real padding: 28
    readonly property bool hasBanners: {
        for (let i = 0; i < banners.count; i++) {
            if (banners.get(i).record.output === output)
                return true;
        }
        return false;
    }

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: 38 // qmllint disable missing-property
    implicitWidth: stack.width + padding * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: hasBanners
    mask: Region {
        regions: [scene, scrollBarRegion]
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
        item: scrollBar.size < 1 ? scrollBar : null
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
                model: window.banners
                Loader {
                    id: loader
                    required property var record
                    active: record.output === window.output
                    width: stack.width
                    sourceComponent: NotificationBanner {
                        record: loader.record
                        onFinished: window.finished(loader.record)
                    }
                }
            }
        }
    }
}
