import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    required property PwNode node
    required property int controlSize
    required property list<PwNode> devices
    required property string title
    property VolumeScroll wheelArea
    signal chooseDevice

    spacing: 4
    visible: node != null || devices.length > 0

    SectionLabel {
        text: root.title
    }
    Button {
        id: deviceControl
        readonly property var port: AudioService.activePort(root.node)
        readonly property string deviceName: root.node?.description || root.node?.nickname || root.node?.name || "No device"

        Layout.fillWidth: true
        leftPadding: volumeRow.leftMargin
        rightPadding: volumeRow.rightMargin - 4
        enabled: root.devices.length > 0
        tooltip.enabled: primary.truncated || secondary.truncated
        tooltip.text: [port?.description, deviceName].filter(Boolean).join("\n")
        onClicked: root.chooseDevice()

        contentItem: RowLayout {
            spacing: 6
            Icon {
                implicitSize: 16
                size: root.controlSize
                name: AudioService.portIconName(deviceControl.port, root.node)
                color: Theme.textSecondary
            }
            ColumnLayout {
                spacing: 2
                Text {
                    id: primary
                    Layout.fillWidth: true
                    text: deviceControl.port?.description || deviceControl.deviceName
                    font.pixelSize: 13
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }
                Text {
                    id: secondary
                    Layout.fillWidth: true
                    visible: deviceControl.port != null
                    text: deviceControl.deviceName
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                }
            }
            Icon {
                implicitSize: 14
                name: "go-next-symbolic"
                color: Theme.textSecondary
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
