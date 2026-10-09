import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.config

Controls.MenuItem {
    id: root
    property string iconName

    Layout.fillWidth: true
    implicitHeight: 30
    opacity: enabled ? 1 : 0.5
    indicator: null

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: RowLayout {
        Icon {
            implicitSize: 16
            name: root.iconName
        }
        Text {
            Layout.fillWidth: true
            color: Theme.textPrimary
            text: root.text
            font: root.font
        }
        Icon {
            implicitSize: 16
            name: "object-select-symbolic"
            visible: root.checked
        }
    }

    background: Rectangle {
        radius: 6
        color: root.down ? Theme.pressedBackground : root.hovered || root.highlighted ? Theme.hoveredBackground : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }
}
