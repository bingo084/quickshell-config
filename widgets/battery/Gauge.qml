import QtQuick
import qs.config

Item {
    id: root
    required property real fraction
    implicitWidth: 80
    implicitHeight: 36
    Rectangle {
        id: body
        width: parent.width - 5
        height: parent.height
        radius: 5
        color: "transparent"
        border.width: 1.5
        border.color: Theme.textSecondary

        Rectangle {
            x: 4
            y: 4
            width: (parent.width - 8) * root.fraction
            height: parent.height - 8
            radius: 2
            color: root.fraction <= 0.15 ? Theme.warning : Theme.accent
        }
    }
    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height * 0.35
        radius: 1
        color: Theme.textSecondary
    }
}
