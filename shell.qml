import QtQuick
import Quickshell
import qs as App

ShellRoot {
    Variants {
        model: Quickshell.screens
        // qmllint disable uncreatable-type
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors {
                left: true
                top: true
                right: true
            }
            implicitHeight: 30

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 10
                }
                text: Qt.formatDateTime(App.Clock.date, "ddd, MMM dd, hh:mm:ss")
            }
        }
    }
}
