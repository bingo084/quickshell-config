pragma ComponentBehavior: Bound

import QtQml.Models as Models
import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.components
import qs.config

ListView {
    id: root
    required property QsMenuHandle menuHandle
    property QsMenuEntry currentEntry: null
    property int pendingMove
    readonly property var entries: opener.children.values
    readonly property bool hasIcons: entries.some(entry => entry.icon !== "")
    property int waitingFor: 0
    readonly property bool hasItems: entries.length > 0 && items.count === entries.length
    readonly property bool ready: hasItems || waitingFor >= 200
    signal selected(QsMenuEntry entry, Item row)
    signal activated(QsMenuEntry entry, Item row)
    signal hovered(QsMenuEntry entry, Item row)
    signal entered
    signal scrolled

    implicitHeight: Math.min(maximumHeight, hasItems ? contentHeight : (notice.visible ? notice.implicitHeight : 0))
    implicitWidth: Math.max(notice.visible ? notice.implicitWidth : 0, ...Array.from({
        length: items.count
    }, (_, index) => (items.get(index) as Item).implicitWidth))
    model: items
    currentIndex: -1
    spacing: 1
    contentWidth: -1
    Controls.ScrollBar.vertical.padding: 0
    visible: ready
    onContentYChanged: root.scrolled()

    onMenuHandleChanged: {
        waitingFor = 0;
        currentEntry = null;
        pendingMove = 0;
        positionViewAtBeginning();
    }

    onHasItemsChanged: waitingFor = 0

    onEntriesChanged: {
        if (currentEntry !== null && !entries.includes(currentEntry))
            select(null, null);
        if (pendingMove !== 0 && entries.length > 0) {
            Qt.callLater(() => {
                if (root.pendingMove !== 0)
                    root.navigate(root.pendingMove);
            });
        }
    }

    function select(entry: QsMenuEntry, row: Item) {
        currentEntry = entry;
        selected(entry, row);
    }

    function navigate(direction: int) {
        if (entries.length === 0) {
            pendingMove = direction;
            return;
        }
        pendingMove = 0;
        const selectable = entries.filter(entry => entry.enabled && !entry.isSeparator);
        if (selectable.length === 0)
            return;
        let index = selectable.indexOf(currentEntry);
        if (index < 0)
            index = direction > 0 ? -1 : 0;
        currentEntry = selectable[(index + direction + selectable.length) % selectable.length];
        root.positionViewAtIndex(entries.indexOf(currentEntry), ListView.Contain);
    }

    function activateCurrent() {
        const index = entries.indexOf(currentEntry);
        if (index < 0)
            return;
        root.positionViewAtIndex(index, ListView.Contain);
        root.forceLayout();
        activated(currentEntry, root.itemAtIndex(index));
    }

    Timer {
        interval: 200
        repeat: true
        running: root.menuHandle !== null && !root.hasItems && root.waitingFor < 5000
        onTriggered: root.waitingFor = Math.min(5000, root.waitingFor + interval)
    }

    Text {
        id: notice
        parent: root
        anchors.fill: parent
        padding: 8
        verticalAlignment: Text.AlignVCenter
        color: Theme.textSecondary
        text: root.waitingFor < 5000 ? "Loading menu…" : "No menu items received"
        visible: !root.hasItems && root.waitingFor >= 200
        elide: Text.ElideRight
    }

    HoverHandler {
        onHoveredChanged: if (hovered)
            root.entered()
    }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Models.ObjectModel {
        id: items
    }

    Models.Instantiator {
        model: opener.children
        onObjectAdded: (index, object) => items.insert(index, object)
        onObjectRemoved: (index, object) => items.remove(object.Models.ObjectModel.index)

        delegate: Loader {
            id: row
            required property QsMenuEntry modelData
            width: root.width
            sourceComponent: modelData ? (modelData.isSeparator ? divider : action) : null

            Component {
                id: action
                MenuItem {
                    id: actionItem
                    property QsMenuEntry entry: row.modelData

                    text: entry?.text ?? ""
                    enabled: entry?.enabled ?? false
                    icon.source: entry ? entry.icon : ""
                    icon.color: "transparent"
                    reserveIcon: root?.hasIcons ?? false
                    hasSubMenu: entry?.hasChildren ?? false
                    checkState: entry?.checkState ?? Qt.Unchecked
                    checked: actionItem.checkState !== Qt.Unchecked
                    radio: entry?.buttonType === QsMenuButtonType.RadioButton
                    highlighted: root?.currentEntry === entry
                    focusPolicy: Qt.NoFocus
                    onHoveredChanged: {
                        if (actionItem.hovered) {
                            root.currentEntry = entry;
                            root.hovered(entry, row);
                        }
                    }
                    onHasSubMenuChanged: {
                        if (entry !== null && root?.currentEntry === entry)
                            root.select(entry, row);
                    }
                    onEnabledChanged: {
                        if (!actionItem.enabled && entry !== null && root?.currentEntry === entry)
                            root.select(null, null);
                    }
                    onTriggered: root.activated(entry, row)
                }
            }
            Component {
                id: divider
                Controls.MenuSeparator {
                    verticalPadding: 4
                    contentItem: Separator {}
                }
            }
        }
    }
}
