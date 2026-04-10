import QtQuick
import Quickshell

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
                anchors.centerIn: parent
                text: "Hello World"
            }
        }
    }
}
