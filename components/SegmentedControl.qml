pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.config

Controls.Control {
    id: root
    required property var model
    property int currentIndex: -1
    property bool animated: true
    readonly property Item selectedButton: buttons.count > 0 ? buttons.itemAt(currentIndex) : null

    signal activated(int index)

    Layout.fillWidth: true
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: 34
    padding: 3
    font.pixelSize: 12
    palette.buttonText: Theme.textSecondary
    palette.highlight: Theme.selectedBackground
    palette.highlightedText: Theme.textOnSelected
    palette.mid: Theme.accent

    background: Rectangle {
        radius: 6
        color: Theme.controlBackground
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth

        Rectangle {
            x: root.selectedButton?.x ?? 0
            width: root.selectedButton?.width ?? 0
            height: parent.height
            radius: 4
            border.width: 1
            border.color: root.palette.mid
            color: root.palette.highlight

            Behavior on x {
                enabled: root.animated
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                enabled: root.animated
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                enabled: root.animated
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        RowLayout {
            id: row
            anchors.fill: parent
            spacing: 0
            uniformCellSizes: true

            Repeater {
                id: buttons
                model: root.model

                Button {
                    id: choice
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 80
                    text: modelData.text ?? ""
                    font: root.font
                    checked: root.currentIndex === index
                    onClicked: root.activated(index)
                    enabled: modelData.enabled ?? true
                    palette.buttonText: checked ? root.palette.highlightedText : hovered || down ? Theme.textPrimary : root.palette.buttonText
                    iconName: modelData.icon ?? ""
                    icon.width: 20
                    icon.height: 20
                    background: null
                    tooltip.text: modelData.tooltip ?? ""
                }
            }
        }
    }
}
