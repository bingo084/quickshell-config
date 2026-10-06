import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.bar as Bar
import qs.config
import qs.services
import qs.widgets.audio

Bar.Button {
    id: root
    property bool outputExpanded: false
    property bool inputExpanded: false

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else {
            Bar.PopupManager.dismiss();
            Audio.toggleMuted();
        }
    }
    onWheel: wheel => {
        Audio.adjustVolume(wheel.angleDelta.y > 0 ? 0.01 : -0.01);
        wheel.accepted = true;
    }

    content: RowLayout {
        spacing: 4
        Icon {
            implicitSize: 18
            color: Audio.muted ? Theme.textSecondary : Theme.textPrimary
            source: Quickshell.iconPath(Audio.volumeIconName(Audio.sink))
        }
        Text {
            color: Audio.muted ? Theme.textSecondary : Theme.textPrimary
            text: Audio.ready ? Audio.percent + "%" : "--%"
        }
    }

    Bar.Popup {
        id: popup
        anchorItem: root
        contentWidth: 300
        onVisibleChanged: {
            if (visible)
                Audio.refreshPorts();
        }

        ColumnLayout {
            spacing: 4

            RowLayout {
                Layout.bottomMargin: 4
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.bold: true
                    text: "Audio"
                }
                Button {
                    icon.name: "preferences-system-symbolic"
                    icon.source: Quickshell.iconPath("emblem-system-symbolic")
                    flat: true
                    onClicked: {
                        popup.visible = false;
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            DeviceSection {
                id: outputSection
                node: Audio.sink
                devices: Audio.sinks
                title: "Output"
                expanded: root.outputExpanded
                onToggleExpanded: {
                    root.inputExpanded = false;
                    root.outputExpanded = !root.outputExpanded;
                }
                onSelected: root.outputExpanded = false
            }

            Separator {
                visible: outputSection.visible && inputSection.visible
            }

            DeviceSection {
                id: inputSection
                node: Audio.source
                devices: Audio.sources
                title: "Input"
                expanded: root.inputExpanded
                onToggleExpanded: {
                    root.outputExpanded = false;
                    root.inputExpanded = !root.inputExpanded;
                }
                onSelected: root.inputExpanded = false
            }

            Separator {
                visible: appsSection.visible && (outputSection.visible || inputSection.visible)
            }

            ColumnLayout {
                id: appsSection
                Layout.fillWidth: true
                spacing: 6
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
