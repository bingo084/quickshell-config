pragma ComponentBehavior: Bound

import QtQml.Models as Models
import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config

WrapperRectangle {
    id: root
    required property QsMenuHandle menuHandle
    required property real maximumHeight
    property QsMenuEntry currentEntry: null
    property int pendingMove
    readonly property var entries: opener.children.values
    readonly property bool hasIcons: entries.some(entry => entry.icon !== "")
    readonly property Region region: Region {
        item: root.visible ? root : null
        radius: root.radius
    }
    signal selected(QsMenuEntry entry, Item row)
    signal activated(QsMenuEntry entry, Item row)
    signal scrolled

    implicitWidth: {
        const widths = Array.from({
            length: items.count
        }, (_, index) => (items.get(index) as Item).implicitWidth);
        const measuredWidth = Math.max(0, ...widths) + root.leftMargin + root.rightMargin;
        return Math.max(120, Math.min(320, measuredWidth));
    }
    margin: 7
    contentInsideBorder: false
    radius: Theme.popupRadius
    color: Theme.popupBackground
    border.width: 1
    border.color: Theme.border
    visible: entries.length > 0

    onEntriesChanged: {
        if (currentEntry !== null && !entries.includes(currentEntry))
            select(null, null);
        if (pendingMove !== 0 && entries.length > 0)
            Qt.callLater(root.move, pendingMove);
    }

    function select(entry: QsMenuEntry, row: Item) {
        currentEntry = entry;
        selected(entry, row);
    }

    function move(direction: int) {
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
        scroll.positionViewAtIndex(entries.indexOf(currentEntry), ListView.Contain);
    }

    function activateCurrent() {
        const index = entries.indexOf(currentEntry);
        if (index < 0)
            return;
        scroll.positionViewAtIndex(index, ListView.Contain);
        scroll.forceLayout();
        activated(currentEntry, scroll.itemAtIndex(index));
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
            width: scroll.width - (scroll.Controls.ScrollBar.vertical.size < 1 ? scroll.Controls.ScrollBar.vertical.implicitWidth + 4 : 0)
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
                        if (actionItem.hovered)
                            root.select(entry, row);
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

    child: ListView {
        id: scroll
        model: items
        currentIndex: -1
        maximumHeight: Math.max(0, root.maximumHeight - root.topMargin - root.bottomMargin)
        spacing: 1
        contentWidth: -1
        onContentYChanged: root.scrolled()
    }
}
