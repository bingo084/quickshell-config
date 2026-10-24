pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: root
    property QsMenuHandle handle: null
    property Item anchorItem: null
    property real center
    readonly property Item bar: anchorItem?.QsWindow.contentItem ?? null
    readonly property var regions: Array.from({
        length: pages.count
    }, (_, index) => (pages.itemAt(index) as TrayMenuPage)?.region).filter(region => region !== undefined)

    grabFocus: true
    color: "transparent"
    implicitWidth: bar?.width ?? 0
    implicitHeight: Math.max(0, (screen?.height ?? 0) - (bar?.height ?? 0) - 4) // qmllint disable missing-property redundant-optional-chaining
    // qmllint disable missing-property unresolved-type unqualified
    anchor {
        item: root.bar
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.bottom: -4
    }
    // qmllint enable missing-property unresolved-type unqualified
    mask: Region {
        regions: root.regions
    }
    BackgroundEffect.blurRegion: Region {
        regions: root.regions
    }
    onClosed: root.close()
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
        if (bar !== item.QsWindow.contentItem)
            close();
        trim(0);
        anchorItem = item;
        handle = menu;
        center = item.mapToItem(bar, item.width / 2, 0).x;
        levels.append({
            menuHandle: menu,
            anchorRow: root.contentItem
        });
        focusScope.forceActiveFocus();
        visible = true;
    }

    function close() {
        visible = false;
        trim(0);
        handle = null;
        anchorItem = null;
    }

    function trim(count: int) {
        while (levels.count > count)
            levels.remove(levels.count - 1);
    }

    function select(level: int, entry: QsMenuEntry, row: Item) {
        if (entry?.enabled && entry.hasChildren) {
            if (levels.count > level + 1 && levels.get(level + 1).menuHandle === entry)
                return;
            trim(level + 1);
            levels.append({
                menuHandle: entry,
                anchorRow: row
            });
        } else {
            trim(level + 1);
        }
    }

    function activate(level: int, entry: QsMenuEntry, row: Item) {
        if (!entry.enabled)
            return;
        if (entry.hasChildren) {
            select(level, entry, row);
            return;
        }
        entry.triggered();
        close();
    }

    ListModel {
        id: levels
    }

    Item {
        id: focusScope
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            const page = pages.itemAt(levels.count - 1) as TrayMenuPage;
            if (!page)
                return;
            if (event.key === Qt.Key_Down)
                page.move(1);
            else if (event.key === Qt.Key_Up)
                page.move(-1);
            else if (event.key === Qt.Key_Right && page.currentEntry?.hasChildren) {
                page.activateCurrent();
                const child = pages.itemAt(levels.count - 1) as TrayMenuPage;
                child?.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                if (levels.count > 1)
                    root.trim(levels.count - 1);
                else
                    root.close();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space)
                page.activateCurrent();
            else
                return;
            event.accepted = true;
        }

        Repeater {
            id: pages
            model: levels
            delegate: TrayMenuPage {
                id: page
                required property int index
                required property Item anchorRow
                readonly property TrayMenuPage parentPage: index > 0 ? pages.itemAt(index - 1) as TrayMenuPage : null
                maximumHeight: root.height
                x: {
                    if (parentPage === null)
                        return Math.max(0, Math.min(root.width - width, root.center - width / 2));
                    const right = parentPage.x + parentPage.width + 4;
                    const left = parentPage.x - width - 4;
                    const previous = index > 1 ? pages.itemAt(index - 2) : null;
                    const preferLeft = previous !== null && parentPage.x < previous.x;
                    return (preferLeft || right + width > root.width) && left >= 0 ? left : Math.max(0, Math.min(root.width - width, right));
                }
                y: Math.max(0, Math.min(root.height - height, index > 0 && anchorRow ? anchorRow.mapToItem(focusScope, 0, 0).y - page.topMargin : 0))
                onSelected: (entry, row) => {
                    if (index >= 0)
                        root.select(index, entry, row);
                }
                onActivated: (entry, row) => root.activate(index, entry, row)
                onScrolled: {
                    if (index >= 0)
                        root.trim(index + 1);
                }
                onAnchorRowChanged: {
                    if (index > 0 && anchorRow === null)
                        root.trim(index);
                }
            }
        }
    }
}
