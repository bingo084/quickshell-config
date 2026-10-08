import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

Button {
    id: root
    required property var node
    property var port

    Layout.fillWidth: true
    flat: true
    checked: (node.type === PwNodeType.AudioSource ? Audio.source : Audio.sink) === node && (!port || Audio.activePort(node)?.name === port.name)
    enabled: port?.availability !== "not available"
    text: (port ? port.description : node.description || node.nickname || node.name) + (enabled ? "" : " · Unavailable")

    contentItem: RowLayout {
        spacing: 6
        Icon {
            implicitSize: 16
            color: root.palette.buttonText
            name: Audio.portIconName(root.port, root.node)
        }
        Text {
            Layout.fillWidth: true
            text: root.text
            color: root.palette.buttonText
            elide: Text.ElideRight
        }
        Icon {
            implicitSize: 16
            color: root.palette.buttonText
            opacity: root.checked ? 1 : 0
            name: "object-select-symbolic"
        }
    }
}
