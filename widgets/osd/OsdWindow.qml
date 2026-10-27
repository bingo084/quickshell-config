pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config

PanelWindow { // qmllint disable uncreatable-type
    id: window
    property real value
    property string iconName
    property bool muted: false
    enum Phase {
        Hidden,
        Open,
        Capturing,
        Closing
    }
    property int phase: OsdWindow.Hidden
    readonly property real cardWidth: 260
    readonly property real cardHeight: 48
    readonly property real padding: shadow.padding
    readonly property real screenX: (screen.width - width) / 2 // qmllint disable missing-property
    readonly property real screenY: screen ? screen.height * 0.9 - cardHeight / 2 - padding : 0 // qmllint disable missing-property

    anchors.top: true
    margins.top: screenY // qmllint disable missing-property
    implicitWidth: cardWidth + padding * 2
    implicitHeight: cardHeight + padding * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: phase !== OsdWindow.Hidden
    color: "transparent"
    mask: Region {}
    BackgroundEffect.blurRegion: phase === OsdWindow.Closing ? null : blurRegion
    Region {
        id: blurRegion
        item: card
        radius: card.radius
    }

    function dismiss() {
        hideTimer.stop();
        fade.stop();
        phase = OsdWindow.Hidden;
        stage.opacity = 0;
    }
    function showOsd() {
        fade.stop();
        phase = OsdWindow.Open;
        fade.to = 1;
        fade.restart();
        hideTimer.restart();
    }
    function closeOsd() {
        if (phase !== OsdWindow.Open)
            return;
        fade.stop();
        frame.startOpacity = stage.opacity;
        phase = OsdWindow.Capturing;
    }
    Item {
        id: stage
        anchors.fill: parent
        visible: window.phase !== OsdWindow.Closing
        opacity: 0
        Shadow {
            id: shadow
            anchors.fill: card
            radius: card.radius
        }
        Rectangle {
            id: card
            x: window.padding
            y: window.padding
            width: window.cardWidth
            height: window.cardHeight
            radius: Theme.popupRadius
            color: Theme.background
            border.color: Theme.border
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12
                Icon {
                    name: window.iconName
                    color: window.muted ? Theme.textSecondary : Theme.textPrimary
                }
                ProgressBar {
                    value: window.value
                    palette.highlight: window.muted ? Theme.textSecondary : Theme.accent
                    Behavior on value {
                        NumberAnimation {
                            duration: 80
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    id: percent
                    Layout.preferredWidth: Math.ceil(percentMetrics.advanceWidth)
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(window.value * 100) + "%"
                    color: window.muted ? Theme.textSecondary : Theme.textPrimary
                    font.pixelSize: 13
                    TextMetrics {
                        id: percentMetrics
                        font: percent.font
                        text: "100%"
                    }
                }
            }
        }
    }
    Loader {
        id: frame
        property real startOpacity: 1
        active: window.phase === OsdWindow.Capturing || window.phase === OsdWindow.Closing
        anchors.fill: parent
        clip: true
        opacity: stage.opacity / Math.max(startOpacity, 0.001)
        sourceComponent: Item {
            ScreencopyView {
                captureSource: window.screen as QtObject
                width: window.screen.width // qmllint disable missing-property
                height: window.screen.height // qmllint disable missing-property
                x: -Math.round(window.screenX * window.devicePixelRatio) / window.devicePixelRatio
                y: -Math.round(window.screenY * window.devicePixelRatio) / window.devicePixelRatio
                onHasContentChanged: {
                    if (hasContent && window.phase === OsdWindow.Capturing) {
                        window.phase = OsdWindow.Closing;
                        fade.to = 0;
                        fade.restart();
                    }
                }
            }
        }
    }
    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: window.closeOsd()
    }
    Timer {
        interval: 300
        running: window.phase === OsdWindow.Capturing
        onTriggered: window.dismiss()
    }
    NumberAnimation {
        id: fade
        target: stage
        property: "opacity"
        duration: 120
        easing.type: Easing.OutCubic
        onFinished: if (window.phase === OsdWindow.Closing)
            window.phase = OsdWindow.Hidden
    }
}
