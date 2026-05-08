pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

WrapperRectangle {
    id: root
    radius: 4
    color: Qt.darker("#ffffff", area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

    property bool outputExpanded: false
    property bool inputExpanded: false

    function changeNodeVolumeFromWheel(node, wheel) {
        Audio.setNodeVolume(node, node.audio.volume + (wheel.angleDelta.y > 0 ? 0.01 : -0.01));
        wheel.accepted = true;
    }

    component IconButton: WrapperRectangle {
        id: button
        required property string icon
        property string fallbackIcon: icon
        property bool checked: false
        property bool subtle: false
        signal clicked

        implicitWidth: 26
        implicitHeight: 24
        radius: 5
        color: checked ? "#eaf3ff" : buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : subtle ? "transparent" : "#f7f7f7"
        border.color: subtle && !buttonArea.containsMouse && !checked ? "transparent" : checked ? "#b7d7ff" : "#e1e1e1"
        border.width: 1

        WrapperMouseArea {
            id: buttonArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 4
            onClicked: button.clicked()

            IconImage {
                implicitSize: 16
                source: Quickshell.iconPath(button.icon, button.fallbackIcon)
            }
        }
    }

    component SectionLabel: Text {
        Layout.fillWidth: true
        color: "#666666"
        font.pixelSize: 11
    }

    component PercentText: Text {
        required property var node
        readonly property bool ready: node?.audio != null

        color: ready && node.audio.muted ? "#777777" : "#1a1a1a"
        text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"
    }

    component VolumeSlider: Rectangle {
        id: slider
        required property var node
        readonly property bool ready: node?.audio != null

        Layout.fillWidth: true
        Layout.preferredHeight: 6
        radius: height / 2
        color: "#ededed"
        enabled: ready
        opacity: ready ? 1 : 0.55

        Rectangle {
            width: parent.width * (slider.ready ? Math.min(slider.node.audio.volume, 1) : 0)
            height: parent.height
            radius: parent.radius
            color: slider.ready && slider.node.audio.muted ? "#a0a0a0" : "#007aff"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => Audio.setNodeVolume(slider.node, mouse.x / slider.width)
            onPositionChanged: mouse => {
                if (pressed)
                    Audio.setNodeVolume(slider.node, mouse.x / slider.width);
            }
            onWheel: wheel => root.changeNodeVolumeFromWheel(slider.node, wheel)
        }
    }

    component DeviceControl: ColumnLayout {
        id: control
        required property var node
        required property bool expanded
        readonly property bool muted: node?.audio != null && node.audio.muted
        property bool expandable: true
        signal toggleExpanded

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconButton {
                icon: Audio.volumeIconName(control.node)
                checked: control.muted
                onClicked: Audio.toggleNodeMuted(control.node)
            }

            WrapperRectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: control.expanded ? "#eaf3ff" : deviceArea.pressed ? "#d9d9d9" : deviceArea.containsMouse ? "#efefef" : "transparent"

                WrapperMouseArea {
                    id: deviceArea
                    hoverEnabled: control.expandable
                    cursorShape: control.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    margin: 6
                    onClicked: {
                        if (control.expandable)
                            control.toggleExpanded();
                    }

                    RowLayout {
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            color: "#1a1a1a"
                            elide: Text.ElideRight
                            text: control.node?.description || control.node?.nickname || control.node?.name || "Audio"
                        }

                        PercentText {
                            node: control.node
                        }

                        IconImage {
                            implicitSize: 14
                            visible: control.expandable
                            source: Quickshell.iconPath(control.expanded ? "pan-up-symbolic" : "pan-down-symbolic")
                        }
                    }
                }
            }
        }

        VolumeSlider {
            node: control.node
        }
    }

    component DeviceListRow: WrapperRectangle {
        id: device
        required property var node
        readonly property var props: node.properties
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 28
        radius: 6
        color: deviceArea.pressed ? "#d9d9d9" : deviceArea.containsMouse ? "#efefef" : "transparent"

        WrapperMouseArea {
            id: deviceArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 6
            onClicked: device.clicked()

            RowLayout {
                spacing: 6

                IconImage {
                    implicitSize: 18
                    source: Quickshell.iconPath(Audio.nodeIconName(device.node))
                }

                Text {
                    Layout.fillWidth: true
                    color: "#1a1a1a"
                    elide: Text.ElideRight
                    text: device.node?.description || device.node?.nickname || device.node?.name || "Audio"
                }

                Text {
                    color: "#777777"
                    font.pixelSize: 11
                    Layout.maximumWidth: 90
                    elide: Text.ElideRight
                    text: device.props["device.profile.description"] || device.props["media.class"] || ""
                    visible: text !== ""
                }
            }
        }
    }

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

    component StreamRow: ColumnLayout {
        id: stream
        required property var node
        readonly property var props: node.properties

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconImage {
                implicitSize: 18
                source: Quickshell.iconPath(Audio.nodeIconName(stream.node))
            }

            Text {
                Layout.fillWidth: true
                color: "#1a1a1a"
                elide: Text.ElideRight
                text: stream.props["application.name"] || stream.node.name
            }

            PercentText {
                node: stream.node
            }

            IconButton {
                icon: Audio.volumeIconName(stream.node)
                checked: stream.node.audio.muted
                subtle: true
                onClicked: Audio.toggleNodeMuted(stream.node)
            }
        }

        VolumeSlider {
            node: stream.node
        }
    }

    WrapperMouseArea {
        id: area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        margin: 6
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                // qmllint disable unresolved-type
                menu.anchor.updateAnchor();
                // qmllint enable unresolved-type
                menu.visible = !menu.visible;
            } else {
                Audio.toggleNodeMuted(Audio.sink);
            }
        }
        onWheel: wheel => root.changeNodeVolumeFromWheel(Audio.sink, wheel)

        RowLayout {
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
    }

    PopupWindow {
        id: menu
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight
        color: "transparent"
        anchor {
            item: root
            // qmllint disable missing-type
            edges: Edges.Bottom
            gravity: Edges.Bottom
            // qmllint enable missing-type
            margins.bottom: -4
        }

        WrapperRectangle {
            id: background
            radius: 8
            color: "#ffffff"
            border.color: "#dcdcdc"
            border.width: 1
            margin: 8

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
                            menu.visible = false;
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
}
