import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root
    required property real fraction
    property real overhang: 1.5
    readonly property real dpr: Window.window?.devicePixelRatio ?? 1
    readonly property point origin: {
        position.transform; // qmllint disable confusing-expression-statement
        return parent.mapToItem(null, 0, 0);
    }

    visible: fraction >= 0
    x: {
        const left = Math.ceil(origin.x * dpr);
        const right = Math.floor((origin.x + parent.width - width) * dpr);
        return (left + Math.round((right - left) * fraction)) / dpr - origin.x;
    }
    y: (Math.round(origin.y * dpr) - Math.round(overhang * dpr)) / dpr - origin.y
    width: Math.round(1.5 * dpr) / dpr
    height: {
        const top = Math.round(origin.y * dpr);
        const bottom = Math.round((origin.y + parent.height) * dpr);
        return (bottom - top + 2 * Math.round(overhang * dpr)) / dpr;
    }
    color: Qt.alpha(Theme.textPrimary, 0.8)

    // mapToItem() needs a dependency on the ancestors' geometry.
    TransformWatcher {
        id: position
        a: root.Window.contentItem
        b: root.parent
    }
}
