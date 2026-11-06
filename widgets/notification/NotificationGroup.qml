pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    required property var entries
    property bool expanded: false
    property real expansion: stacked && expanded ? 1 : 0
    property Loader preview: null
    readonly property int count: entries?.count ?? 0
    readonly property bool stacked: count > 1
    readonly property bool folded: stacked && !expanded
    readonly property string appName: count > 0 ? entries.get(0).record.snapshot.appName || "Notifications" : ""
    readonly property real previewHeight: preview?.height ?? 0
    readonly property real stackDepth: Math.min(2, Math.max(0, count - 1)) * 5
    readonly property var layout: {
        const positions = [];
        let height = root.stacked ? header.height + 10 : 0;
        for (let i = 0; i < cards.count; i++) {
            if (i > 0)
                height += 10;
            positions.push(height);
            height += cards.itemAt(i)?.height ?? 0;
        }
        return {
            positions,
            height
        };
    }
    readonly property Region region: Region {
        regions: [...(root.expansion > 0 ? [header.region] : []), ...(root.stacked && root.expansion < 1 ? [backing.region] : []), ...Array.from({
                length: cards.count
            }, (_, i) => {
                const loader = cards.itemAt(i) as Loader;
                const card = loader?.item as NotificationCard;
                return loader?.visible && card ? card.region : null;
            }).filter(Boolean), ...(root.clip ? [bounds] : [])]
    }
    signal actionInvoked

    implicitHeight: count > 0 ? (previewHeight + stackDepth) * (1 - expansion) + layout.height * expansion : 0
    height: implicitHeight
    clip: expansion > 0 && expansion < 1
    Behavior on expansion {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Region {
        id: bounds
        item: root
        intersection: Intersection.Intersect
    }
    Item {
        id: backing
        readonly property var plates: Array.from(children).filter(item => item instanceof Rectangle)
        readonly property Region region: Region {
            regions: backing.plates.map(plate => plate.region)
        }

        y: root.preview?.y ?? 0
        width: root.width
        height: root.previewHeight + root.stackDepth
        // Apply transparency once so overlapping plates do not become brighter.
        opacity: Theme.background.a
        layer.enabled: true
        Repeater {
            model: Math.min(root.count, 3)
            Rectangle {
                id: plate
                required property int index
                readonly property Region region: Region {
                    item: plate
                    radius: plate.radius
                }

                x: index * 6
                y: index * 5
                z: -index
                width: parent.width - 2 * x
                height: root.previewHeight
                radius: 18
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)
                opacity: index === 0 ? 1 : 1 - root.expansion
                border.width: 1
                border.color: Qt.tint(color, Theme.border)
            }
        }
    }

    RowLayout {
        id: header
        readonly property Region region: Region {
            regions: [showLess.region, clearGroup.region]
        }

        width: root.width
        height: 28
        opacity: root.expansion
        visible: opacity > 0
        enabled: root.expanded
        spacing: 6
        Text {
            Layout.fillWidth: true
            text: root.appName
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: "white"
            style: Text.Outline
            styleColor: "#40000000"
            elide: Text.ElideRight
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#99000000"
                blurMax: 8
                shadowBlur: 0.5
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 1
            }
        }
        NotificationButton {
            id: showLess
            Layout.preferredHeight: clearGroup.size
            text: "Show less"
            onClicked: root.expanded = false
        }
        DismissButton {
            id: clearGroup
            expandable: true
            onClicked: NotificationService.clearGroup(root.entries)
        }
    }

    Repeater {
        id: cards
        model: root.entries
        Loader {
            id: loader
            required property int index
            required property var record
            property var entry: record
            active: index === 0 || root.expanded || root.expansion > 0
            visible: active && opacity > 0
            opacity: index === 0 ? 1 : root.expansion
            y: Math.min(index, 2) * 5 * (1 - root.expansion) + (root.layout.positions[index] ?? 0) * root.expansion
            z: cards.count - index
            width: root.width
            onIndexChanged: {
                if (index === 0)
                    root.preview = loader;
            }
            Component.onCompleted: {
                entry = record;
                if (index === 0)
                    root.preview = loader;
            }
            sourceComponent: NotificationCard {
                record: loader.entry
                backgroundVisible: loader.index !== 0
                stackCount: root.folded ? root.count : 1
                onDismissRequested: group => {
                    if (group)
                        NotificationService.clearGroup(root.entries);
                    else
                        NotificationService.dismiss(record);
                }
                onActionInvoked: root.actionInvoked()

                function toggleExpanded() {
                    if (root.folded)
                        root.expanded = true;
                    else
                        expanded = !expanded;
                }
            }
        }
    }
}
