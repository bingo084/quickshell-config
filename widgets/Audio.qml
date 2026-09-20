import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.services
import qs.widgets.audio

Button {
    id: root
    property bool outputExpanded: false
    property bool inputExpanded: false

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else {
            PopupManager.dismiss();
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

    Popup {
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
