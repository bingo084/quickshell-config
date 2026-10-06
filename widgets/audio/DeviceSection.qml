pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services

ColumnLayout {
    id: root
    required property PwNode node
    required property list<PwNode> devices
    required property bool expanded
    property string title: ""
    signal toggleExpanded
    signal selected(PwNode node)
    readonly property int optionCount: devices.reduce((count, device) => count + Math.max(1, Audio.ports(device).length), 0)

    Layout.fillWidth: true
    spacing: 4
    visible: node != null || devices.length > 0

    SectionLabel {
        text: root.title
        visible: root.title !== ""
    }

    DeviceControl {
        node: root.node
        expanded: root.expanded
        expandable: root.optionCount > 1
        onToggleExpanded: root.toggleExpanded()
    }

    Flickable {
        id: list
        Layout.fillWidth: true
        implicitHeight: Math.min(entries.implicitHeight, 220)
        contentHeight: entries.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        visible: root.expanded && root.optionCount > 1
        Controls.ScrollBar.vertical: Controls.ScrollBar {}

        ColumnLayout {
            id: entries
            width: list.width
            spacing: 4

            Repeater {
                model: root.devices

                ColumnLayout {
                    id: group
                    required property PwNode modelData
                    readonly property var ports: Audio.ports(modelData)

                    Layout.fillWidth: true
                    spacing: 2
                    SectionLabel {
                        text: group.modelData.description || group.modelData.nickname || group.modelData.name
                        visible: group.ports.length > 0
                        elide: Text.ElideRight
                    }

                    Repeater {
                        model: group.ports.length ? group.ports : [null]
                        DeviceListRow {
                            required property var modelData

                            node: group.modelData
                            port: modelData
                            onClicked: {
                                if (Audio.selectDevice(node, port))
                                    root.selected(node);
                            }
                        }
                    }
                }
            }
        }
    }
}
