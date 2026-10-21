import QtQuick
import QtQuick.Layouts
import Quickshell

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

        Icon {
            Layout.rightMargin: root.spacing
            visible: name !== "" || source.toString() !== ""
            name: root.icon.name
            source: root.icon.source
            implicitSize: root.icon.width
            color: root.icon.color
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
