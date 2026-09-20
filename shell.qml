import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.bar
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

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: PopupManager.dismiss()
            }

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 10
                }

                Power {
                    screen: bar.modelData
                }
                Search {}
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
                Battery {}
                Clock {}
            }
        }
    }
}
