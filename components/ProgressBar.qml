import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config

ProgressBar {
    id: root
    property int level
    property real tickPosition: -1
    property real tickOverhang: 1.5

    Layout.fillWidth: true
    implicitWidth: 200
    implicitHeight: 4
    padding: 0
    palette.highlight: Theme.levelColor(root.level)
    palette.mid: Theme.trackBackground

    background: Rectangle {
        radius: height / 2
        color: root.palette.mid
    }

    contentItem: Item {
        Rectangle {
            width: root.position * parent.width
            height: parent.height
            radius: height / 2
            color: root.palette.highlight
        }

        Rectangle {
            readonly property real dpr: Window.window?.devicePixelRatio ?? 1
            readonly property point origin: {
                geometry.transform; // qmllint disable confusing-expression-statement
                return parent.mapToItem(null, 0, 0);
            }

            visible: root.tickPosition >= 0
            x: {
                const left = Math.ceil(origin.x * dpr);
                const right = Math.floor((origin.x + parent.width - width) * dpr);
                return (left + Math.round((right - left) * root.tickPosition)) / dpr - origin.x;
            }
            y: (Math.round(origin.y * dpr) - Math.round(root.tickOverhang * dpr)) / dpr - origin.y
            width: Math.round(1.5 * dpr) / dpr
            height: {
                const top = Math.round(origin.y * dpr);
                const bottom = Math.round((origin.y + parent.height) * dpr);
                return (bottom - top + 2 * Math.round(root.tickOverhang * dpr)) / dpr;
            }
            color: Theme.textSecondary

            // mapToItem() needs a dependency on the ancestors' geometry.
            TransformWatcher {
                id: geometry
                a: root.Window.contentItem
                b: root.contentItem
            }
        }
    }
}
