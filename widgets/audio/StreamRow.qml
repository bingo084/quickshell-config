import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    required property PwNode node
    required property int controlSize
    property VolumeScroll wheelArea
    readonly property string appName: node.properties["application.name"] || node.name
    readonly property string mediaName: node.properties["media.name"] || ""

    spacing: 3

    WrapperItem {
        Layout.fillWidth: true
        leftMargin: volumeRow.leftMargin
        rightMargin: volumeRow.rightMargin

        RowLayout {
            spacing: 6
            Icon {
                size: root.controlSize
                colorize: false
                source: Quickshell.iconPath(Audio.nodeIconName(root.node))
            }
            ColumnLayout {
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    text: root.appName
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.mediaName !== "" && root.mediaName !== root.appName
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    text: root.mediaName
                }
            }
        }
    }
    VolumeRow {
        id: volumeRow
        node: root.node
        controlSize: root.controlSize
        wheelArea: root.wheelArea
    }
}
