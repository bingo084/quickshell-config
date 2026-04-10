import QtQuick
import Quickshell
import qs.widgets

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

            Audio {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: clock.left
                    rightMargin: 10
                }
            }

            Clock {
              id: clock
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 10
                }
            }
        }
    }
}
