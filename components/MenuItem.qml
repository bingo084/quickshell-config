import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.config

Controls.MenuItem {
    id: root
    property string iconName
    property bool reserveIcon: true
    property bool radio
    property int checkState: checked ? Qt.Checked : Qt.Unchecked

    Layout.fillWidth: true
    implicitHeight: 30
    opacity: enabled ? 1 : 0.5
    indicator: null
    arrow: null
    icon.name: root.iconName
    icon.color: Theme.textPrimary

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: RowLayout {
        Icon {
            visible: root.reserveIcon
            implicitSize: 16
            name: root.icon.name
            source: root.icon.source
            color: root.icon.color
        }
        Text {
            id: label
            Layout.fillWidth: true
            color: Theme.textPrimary
            text: root.text
            font: root.font
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }
        Item {
            implicitWidth: 16
            implicitHeight: 16
            visible: root.checked || root.subMenu !== null

            Icon {
                anchors.centerIn: parent
                implicitSize: root.subMenu ? 12 : 16
                visible: !root.radio || root.subMenu !== null
                name: root.subMenu ? "go-next-symbolic" : root.checkState === Qt.PartiallyChecked ? "list-remove-symbolic" : "object-select-symbolic"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: width
                radius: width / 2
                visible: root.radio && root.subMenu === null
                color: Theme.textPrimary
            }
        }
    }

    Tooltip {
        anchorItem: root
        enabled: label.truncated
        text: root.text
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
