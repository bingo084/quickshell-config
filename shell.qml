import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.widgets

ShellRoot {
    Variants {
        model: Quickshell.screens
        // qmllint disable uncreatable-type
        PanelWindow {
            id: bar
            required property ShellScreen modelData
            screen: modelData
            anchors {
                left: true
                top: true
                right: true
            }
            implicitHeight: 30

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 10
                }

                Workspaces {
                    screen: bar.modelData
                }
                Windows {
                    screen: bar.modelData
                }
            }

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 10
                }

                Audio {}
                Clock {}
            }
        }
    }
}
