import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Button {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    font.pixelSize: 12
    enabled: text !== ""
    onClicked: Quickshell.clipboardText = text

    contentItem: RowLayout {
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        IconImage {
            Layout.rightMargin: root.spacing
            visible: root.icon.source.toString() !== ""
            source: root.icon.source
            implicitSize: root.icon.width
        }

        Text {
            id: label
            Layout.fillWidth: true
            Layout.maximumWidth: Math.ceil(implicitWidth)
            text: root.text
            font: root.font
            color: root.palette.active.buttonText
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    tooltip.enabled: label.truncated
    tooltip.text: root.text
}
