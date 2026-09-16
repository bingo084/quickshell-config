pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import qs.widgets.audio

BarButton {
    id: root
    property bool outputExpanded: false
    property bool inputExpanded: false

    component DeviceSection: ColumnLayout {
        id: section
        required property var node
        required property var devices
        property bool expanded: false
        property string title: ""
        signal toggleExpanded
        signal selected(var node)

        Layout.fillWidth: true
        spacing: 4
        visible: node != null || devices.length > 0

        SectionLabel {
            text: section.title
            visible: section.title !== ""
        }

        DeviceControl {
            node: section.node
            expanded: section.expanded
            expandable: section.devices.length > 1
            onToggleExpanded: section.toggleExpanded()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: section.expanded && section.devices.length > 1

            Repeater {
                model: section.devices.filter(node => node !== section.node)

                DeviceListRow {
                    required property var modelData
                    node: modelData
                    onClicked: section.selected(modelData)
                }
            }
        }
    }

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            // qmllint disable unresolved-type
            popup.anchor.updateAnchor();
            // qmllint enable unresolved-type
            popup.visible = !popup.visible;
        } else {
            Audio.toggleMuted();
        }
    }
    onWheel: wheel => {
        Audio.adjustVolume(wheel.angleDelta.y > 0 ? 0.01 : -0.01);
        wheel.accepted = true;
    }

    content: RowLayout {
        spacing: 4

        IconImage {
            implicitSize: 18
            source: Quickshell.iconPath(Audio.volumeIconName(Audio.sink))
        }

        Text {
            color: Audio.muted ? "#777777" : "#1a1a1a"
            text: Audio.ready ? Audio.percent + "%" : "--%"
        }
    }

    BarPopup {
        id: popup
        anchorItem: root

        ColumnLayout {
            spacing: 8

            RowLayout {
                Layout.preferredWidth: 300
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    color: "#1a1a1a"
                    font.bold: true
                    text: "Audio"
                }

                IconButton {
                    icon: "preferences-system-symbolic"
                    fallbackIcon: "emblem-system-symbolic"
                    subtle: true
                    onClicked: {
                        popup.visible = false;
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            DeviceSection {
                node: Audio.sink
                devices: Audio.sinks
                title: "Output"
                expanded: root.outputExpanded
                onToggleExpanded: {
                    root.inputExpanded = false;
                    root.outputExpanded = !root.outputExpanded;
                }
                onSelected: node => {
                    Audio.setSink(node);
                    root.outputExpanded = false;
                }
            }

            DeviceSection {
                node: Audio.source
                devices: Audio.sources
                title: "Input"
                expanded: root.inputExpanded
                onToggleExpanded: {
                    root.outputExpanded = false;
                    root.inputExpanded = !root.inputExpanded;
                }
                onSelected: node => {
                    Audio.setSource(node);
                    root.inputExpanded = false;
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: Audio.streams.length > 0

                SectionLabel {
                    text: "Apps"
                }

                Repeater {
                    model: Audio.streams

                    StreamRow {
                        required property var modelData
                        node: modelData
                    }
                }
            }
        }
    }
}
