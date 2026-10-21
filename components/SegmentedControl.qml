pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.config
import qs.services

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
        color: Qt.tint(Theme.meterBackground, Theme.hoveredBackground)
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

                Controls.Button {
                    id: choice
                    required property int index
                    required property var modelData
                    readonly property var resolvedIcon: Icons.resolve(modelData.icon ?? "")

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 80
                    text: modelData.text ?? ""
                    font: root.font
                    checked: root.currentIndex === index
                    onClicked: root.activated(index)
                    enabled: modelData.enabled ?? true
                    opacity: enabled ? 1 : 0.5
                    palette.buttonText: checked ? root.palette.highlightedText : hovered || down ? Theme.textPrimary : root.palette.buttonText
                    icon.name: resolvedIcon.name
                    icon.source: resolvedIcon.source
                    icon.cache: false
                    icon.width: 20
                    icon.height: 20
                    icon.color: palette.buttonText
                    background: null

                    Behavior on palette.buttonText {
                        enabled: root.animated
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    Tooltip {
                        anchorItem: choice
                        text: choice.modelData.tooltip ?? ""
                        enabled: text !== ""
                    }
                }
            }
        }
    }
}
