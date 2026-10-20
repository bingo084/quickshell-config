pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.components.bar as Bar
import qs.config
import qs.services

Bar.Popup {
    id: root
    readonly property int controlSize: 32
    property string page: ""
    readonly property PwNode selectedNode: page === "input" ? Audio.source : Audio.sink

    contentWidth: 316
    contentMargin: 13
    onVisibleChanged: {
        if (visible) {
            page = "";
            Audio.refreshPorts();
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
                    font.bold: true
                    text: "Audio"
                }
                Button {
                    Layout.preferredWidth: root.controlSize
                    Layout.preferredHeight: root.controlSize
                    radius: height / 2
                    iconName: "preferences-system-symbolic"
                    icon.width: 16
                    icon.height: 16
                    tooltip.text: "Audio settings"
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            VolumeScroll {
                id: mainViewport
                Layout.fillWidth: true
                implicitHeight: Math.min(mainBody.implicitHeight, 420)
                contentHeight: mainBody.implicitHeight

                ColumnLayout {
                    id: mainBody
                    width: mainViewport.contentWidthAvailable
                    spacing: 10

                    DeviceSection {
                        id: outputSection
                        node: Audio.sink
                        controlSize: root.controlSize
                        devices: Audio.sinks
                        title: "Output"
                        wheelArea: mainViewport
                        onChooseDevice: root.openPicker("output")
                    }
                    Separator {
                        visible: outputSection.visible && inputSection.visible
                    }
                    DeviceSection {
                        id: inputSection
                        node: Audio.source
                        controlSize: root.controlSize
                        devices: Audio.sources
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
                        visible: Audio.streams.length > 0

                        SectionLabel {
                            text: "Apps"
                        }
                        Repeater {
                            model: Audio.streams
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
        }

        ColumnLayout {
            spacing: 10
            visible: root.page !== ""

            RowLayout {
                Button {
                    Layout.preferredWidth: root.controlSize
                    Layout.preferredHeight: root.controlSize
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    tooltip.text: "Back to Audio"
                    onClicked: root.page = ""
                }
                Text {
                    Layout.fillWidth: true
                    text: root.page === "input" ? "Input" : "Output"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: selectedVolume.leftMargin
                Layout.rightMargin: selectedVolume.rightMargin
                readonly property var port: Audio.activePort(root.selectedNode)
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
                devices: root.page === "input" ? Audio.sources : Audio.sinks
                onSelected: root.page = ""
            }
        }
    }
}
