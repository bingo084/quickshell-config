import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config

// qmllint disable uncreatable-type
PanelWindow {
    id: root
    required property string actionLabel
    component TimeoutConfig: QtObject {
        property int seconds: 10
        property string action: "confirm"
    }
    readonly property TimeoutConfig timeout: TimeoutConfig {}
    property int remainingSeconds
    signal canceled
    signal confirmed

    visible: false
    color: "#66000000"

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: {
        if (visible)
            root.remainingSeconds = timeout.seconds;
    }

    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -(parent.height - height) / 4
        width: 320
        height: 150
        color: Theme.popupBackground
        border.color: Theme.popupBorder
        radius: Theme.popupRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: `Are you sure you want to ${root.actionLabel}?`
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 30
                    radius: 6
                    color: cancelArea.containsMouse ? "#efefef" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        color: Theme.textPrimary
                        text: root.timeout.action === "cancel" && root.remainingSeconds > 0 ? `Cancel (${root.remainingSeconds})` : "Cancel"
                    }
                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.canceled()
                    }
                }
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 30
                    radius: 6
                    color: confirmArea.containsMouse ? "#efefef" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        color: Theme.textPrimary
                        text: root.timeout.action === "confirm" && root.remainingSeconds > 0 ? `${root.actionLabel} (${root.remainingSeconds})` : root.actionLabel
                    }
                    MouseArea {
                        id: confirmArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmed()
                    }
                }
            }
        }
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.canceled()
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.remainingSeconds > 0
        onTriggered: {
            root.remainingSeconds--;
            if (root.remainingSeconds === 0)
                root.timeout.action === "confirm" ? root.confirmed() : root.canceled();
        }
    }
}
