pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

Flickable {
    id: root
    required property list<PwNode> devices
    signal selected

    Repeater {
        model: root.devices
        ColumnLayout {
            id: group
            required property PwNode modelData
            readonly property var ports: AudioService.ports(modelData)

            spacing: 3

            Controls.Button {
                id: heading
                Layout.fillWidth: true
                padding: 6
                onClicked: {
                    if (group.ports.length === 0 && AudioService.selectDevice(group.modelData, null))
                        root.selected();
                }
                contentItem: RowLayout {
                    spacing: 6
                    Icon {
                        implicitSize: 16
                        name: AudioService.nodeIconName(group.modelData)
                        color: Theme.textSecondary
                    }
                    Text {
                        id: deviceName
                        Layout.fillWidth: true
                        text: group.modelData.description || group.modelData.nickname || group.modelData.name
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Tooltip {
                            anchorItem: deviceName
                            enabled: deviceName.truncated
                            text: deviceName.text
                        }
                    }
                    Icon {
                        implicitSize: 14
                        name: "object-select-symbolic"
                        visible: group.ports.length === 0 && (group.modelData.type === PwNodeType.AudioSource ? AudioService.source : AudioService.sink) === group.modelData
                        color: Theme.accent
                    }
                }
                background: Rectangle {
                    radius: 4
                    color: group.ports.length === 0 && heading.hovered ? Theme.hoverOverlay : "transparent"
                }
                HoverHandler {
                    cursorShape: group.ports.length === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            ColumnLayout {
                Layout.leftMargin: 20
                spacing: 2
                visible: group.ports.length > 0
                Repeater {
                    model: group.ports
                    Button {
                        id: entry
                        required property var modelData

                        Layout.fillWidth: true
                        checked: group.modelData !== null && (group.modelData.type === PwNodeType.AudioSource ? AudioService.source : AudioService.sink) === group.modelData && AudioService.activePort(group.modelData)?.name === modelData.name
                        enabled: modelData.availability !== "not available"
                        text: modelData.description
                        tooltip.enabled: portName.truncated
                        tooltip.text: text
                        onClicked: {
                            if (AudioService.selectDevice(group.modelData, modelData))
                                root.selected();
                        }

                        contentItem: RowLayout {
                            spacing: 6
                            Icon {
                                implicitSize: 16
                                color: entry.checked ? Theme.accent : Theme.textPrimary
                                name: AudioService.portIconName(entry.modelData, group.modelData)
                            }
                            Text {
                                id: portName
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                text: entry.text
                                color: entry.checked ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: !entry.enabled
                                text: "Unavailable"
                                font.pixelSize: 10
                                color: Theme.textSecondary
                            }
                            Icon {
                                implicitSize: 14
                                color: Theme.accent
                                visible: entry.checked
                                name: "object-select-symbolic"
                            }
                        }
                    }
                }
            }
        }
    }
}
