pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    required property PwNode node
    required property var devices
    required property bool expanded
    property string title: ""
    signal toggleExpanded
    signal selected(PwNode node)

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
        expandable: root.devices.length > 1
        onToggleExpanded: root.toggleExpanded()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: root.expanded && root.devices.length > 1

        Repeater {
            model: root.devices.filter(node => node !== root.node)

            DeviceListRow {
                required property var modelData
                node: modelData
                onClicked: root.selected(modelData)
            }
        }
    }
}
