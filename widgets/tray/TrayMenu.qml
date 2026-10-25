pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components

Popup {
    id: root
    property QsMenuHandle handle: null
    anchorItem: null
    contentMargin: 6
    contentWidth: menuPage.implicitWidth
    minimumWidth: 120
    maximumWidth: 320
    ready: menuPage.ready
    regions: Array.from({
        length: pages.count
    }, (_, index) => (pages.itemAt(index) as WrapperRectangle)?.region).filter(region => region !== undefined) // qmllint disable missing-property

    onVisibleChanged: {
        if (!visible) {
            trim(0);
            handle = null;
        }
    }
    onHandleChanged: {
        if (visible && handle === null)
            root.close();
    }
    onAnchorItemChanged: {
        if (visible && anchorItem === null)
            root.close();
    }

    function toggle(menu: QsMenuHandle, item: Item) {
        if (visible && handle === menu && anchorItem === item) {
            close();
            return;
        }
        trim(0);
        handle = menu;
        open(item);
    }

    function trim(count: int) {
        hoverSwitch.stop();
        while (levels.count > count)
            levels.remove(levels.count - 1);
    }

    function select(level: int, entry: QsMenuEntry, row: Item) {
        hoverSwitch.stop();
        if (entry?.enabled && entry.hasChildren) {
            if (levels.count > level && levels.get(level).menuHandle === entry)
                return;
            trim(level);
            levels.append({
                menuHandle: entry,
                anchorRow: row
            });
        } else {
            trim(level);
        }
    }

    function activate(level: int, entry: QsMenuEntry, row: Item) {
        hoverSwitch.stop();
        if (!entry.enabled)
            return;
        if (entry.hasChildren) {
            select(level, entry, row);
            return;
        }
        entry.triggered();
        close();
    }

    function hover(level: int, entry: QsMenuEntry, row: Item) {
        hoverSwitch.stop();
        if (levels.count <= level) {
            select(level, entry, row);
            return;
        }
        if (levels.get(level).menuHandle === entry)
            return;
        hoverSwitch.level = level;
        hoverSwitch.entry = entry;
        hoverSwitch.row = row;
        hoverSwitch.restart();
    }

    function enter(level: int) {
        if (hoverSwitch.running && level > hoverSwitch.level)
            hoverSwitch.stop();
    }

    content: TrayMenuPage {
        id: menuPage
        menuHandle: root.handle
        maximumHeight: Math.max(0, PopupHost.height - 2 * PopupHost.card.inset)
        onSelected: (entry, row) => root.select(0, entry, row)
        onHovered: (entry, row) => root.hover(0, entry, row)
        onEntered: root.enter(0)
        onActivated: (entry, row) => root.activate(0, entry, row)
        onScrolled: root.trim(0)
        Keys.onPressed: event => {
            const page = levels.count === 0 ? menuPage : (pages.itemAt(levels.count - 1) as WrapperRectangle)?.child as TrayMenuPage;
            if (!page)
                return;
            if (event.key === Qt.Key_Down)
                page.navigate(1);
            else if (event.key === Qt.Key_Up)
                page.navigate(-1);
            else if (event.key === Qt.Key_Right && page.currentEntry?.hasChildren) {
                page.activateCurrent();
                const child = (pages.itemAt(levels.count - 1) as WrapperRectangle)?.child as TrayMenuPage;
                child?.navigate(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                if (levels.count > 0)
                    root.trim(levels.count - 1);
                else
                    root.close();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space)
                page.activateCurrent();
            else
                return;
            event.accepted = true;
        }
    }

    overlay: Item {
        id: scene
        anchors.fill: parent

        Timer {
            id: hoverSwitch
            property int level
            property QsMenuEntry entry: null
            property Item row: null
            interval: 180
            onTriggered: root.select(level, entry, row)
        }

        ListModel {
            id: levels
        }

        Repeater {
            id: pages
            model: levels
            delegate: WrapperRectangle {
                id: card
                required property int index
                required property QsMenuHandle menuHandle
                required property Item anchorRow
                readonly property Item parentCard: index <= 0 ? PopupHost.card : pages.itemAt(index - 1)
                readonly property Region region: Region {
                    item: card.visible ? card : null
                    radius: card.radius
                }

                margin: PopupHost.card.inset
                contentInsideBorder: false
                implicitWidth: Math.max(120, Math.min(320, child.implicitWidth + 2 * margin))
                radius: PopupHost.card.radius
                color: PopupHost.card.color
                border.width: 1
                border.color: PopupHost.card.border.color
                visible: (child as TrayMenuPage)?.ready ?? false
                x: {
                    const right = parentCard.x + parentCard.width + 4;
                    const left = parentCard.x - width - 4;
                    const previous = index > 0 ? (index === 1 ? PopupHost.card : pages.itemAt(index - 2)) : null;
                    const preferLeft = previous !== null && parentCard.x < previous.x;
                    return (preferLeft || right + width > scene.width) && left >= 0 ? left : Math.max(0, Math.min(scene.width - width, right));
                }
                y: Math.max(0, Math.min(scene.height - height, anchorRow ? anchorRow.mapToItem(scene, 0, 0).y - margin : 0))
                onAnchorRowChanged: {
                    if (index >= 0 && anchorRow === null)
                        root.trim(index);
                }

                Shadow {
                    parent: scene
                    anchors.fill: card
                    radius: card.radius
                    visible: card.visible
                    z: -1
                }

                child: TrayMenuPage {
                    menuHandle: card.menuHandle
                    maximumHeight: Math.max(0, PopupHost.height - 2 * card.margin)
                    onSelected: (entry, row) => {
                        if (card.index >= 0)
                            root.select(card.index + 1, entry, row);
                    }
                    onHovered: (entry, row) => {
                        if (card.index >= 0)
                            root.hover(card.index + 1, entry, row);
                    }
                    onEntered: root.enter(card.index + 1)
                    onActivated: (entry, row) => root.activate(card.index + 1, entry, row)
                    onScrolled: {
                        if (card.index >= 0)
                            root.trim(card.index + 1);
                    }
                }
            }
        }
    }
}
