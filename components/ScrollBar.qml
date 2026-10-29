import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config

ScrollBar {
    id: root
    required property Item viewport
    readonly property point origin: {
        geometry.transform; // qmllint disable confusing-expression-statement
        return viewport.mapToItem(parent, viewport.width, 0);
    }

    parent: {
        let item = viewport.parent;
        while (item instanceof ColumnLayout || item instanceof RowLayout || item instanceof GridLayout)
            item = item.parent;
        return item;
    }
    x: origin.x + padding
    y: origin.y
    height: viewport.height
    visible: viewport.visible && policy !== ScrollBar.AlwaysOff
    enabled: viewport.enabled
    opacity: {
        let opacity = 1;
        for (let item = viewport; item && item !== parent; item = item.parent)
            opacity *= item.opacity;
        return opacity;
    }
    palette.mid: hovered ? Theme.scrollThumbHover : Theme.scrollThumb
    palette.dark: Theme.scrollThumbPress

    TransformWatcher {
        id: geometry
        a: root.parent
        b: root.viewport
    }

    Behavior on palette.mid {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
}
