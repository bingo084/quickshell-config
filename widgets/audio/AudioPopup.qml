pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

Popup {
    id: root
    readonly property int controlSize: 32
    property string page: ""
    readonly property PwNode selectedNode: page === "input" ? AudioService.source : AudioService.sink

    preferredWidth: 360
    onVisibleChanged: {
        if (visible) {
            page = "";
            AudioService.refreshPorts();
        }
    }

    function openPicker(page: string) {
        picker.contentY = 0;
        root.page = page;
    }

    ColumnLayout {
        ColumnLayout {
            spacing: 10
            visible: root.page === ""

            RowLayout {
                Layout.leftMargin: 6

                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    text: "Audio"
                }
                Button {
                    size: root.controlSize
                    radius: height / 2
                    iconName: "preferences-system-symbolic"
                    tooltip.text: "Audio settings"
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            VolumeScroll {
                id: mainViewport
                spacing: 10

                DeviceSection {
                    id: outputSection
                    node: AudioService.sink
                    controlSize: root.controlSize
                    devices: AudioService.sinks
                    title: "Output"
                    wheelArea: mainViewport
                    onChooseDevice: root.openPicker("output")
                }
                Separator {
                    visible: outputSection.visible && inputSection.visible
                }
                DeviceSection {
                    id: inputSection
                    node: AudioService.source
                    controlSize: root.controlSize
                    devices: AudioService.sources
                    title: "Input"
                    wheelArea: mainViewport
                    onChooseDevice: root.openPicker("input")
                }
                Separator {
                    visible: appsSection.visible && (outputSection.visible || inputSection.visible)
                }
                ColumnLayout {
                    id: appsSection
                    spacing: 10
                    visible: AudioService.streams.length > 0

                    SectionLabel {
                        text: "Apps"
                    }
                    Repeater {
                        model: AudioService.streams
                        StreamRow {
                            required property PwNode modelData
                            node: modelData
                            controlSize: root.controlSize
                            wheelArea: mainViewport
                        }
                    }
                }
                Text {
                    visible: !outputSection.visible && !inputSection.visible && !appsSection.visible
                    Layout.leftMargin: 6
                    color: Theme.textSecondary
                    text: "No audio devices"
                }
            }
        }

        ColumnLayout {
            spacing: 10
            visible: root.page !== ""

            RowLayout {
                Button {
                    size: root.controlSize
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    tooltip.text: "Back to Audio"
                    onClicked: root.page = ""
                }
                Text {
                    Layout.fillWidth: true
                    text: root.page === "input" ? "Input" : "Output"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: selectedVolume.leftMargin
                Layout.rightMargin: selectedVolume.rightMargin
                readonly property var port: AudioService.activePort(root.selectedNode)
                text: port?.description || root.selectedNode?.description || root.selectedNode?.nickname || root.selectedNode?.name || "No device"
                color: Theme.textSecondary
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            VolumeRow {
                id: selectedVolume
                node: root.selectedNode
                controlSize: root.controlSize
            }
            Separator {}
            DevicePicker {
                id: picker
                devices: root.page === "input" ? AudioService.sources : AudioService.sinks
                onSelected: root.page = ""
            }
        }
    }
}
