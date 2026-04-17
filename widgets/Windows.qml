pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen
    spacing: 0

    Repeater {
        model: Niri.workspaces

        Repeater {
            id: workspace
            required property int id
            required property bool isActive
            required property string output
            model: isActive && output === root.screen.name ? Niri.sortedWindows : 0

            Rectangle {
                id: window
                required property int index
                required property int id
                required property string title
                required property string appId
                required property int workspaceId
                required property bool isFocused
                required property string iconPath
                readonly property color baseColor: isFocused ? "#eeeeee" : "#ffffff"
                visible: workspace.id === window.workspaceId
                implicitWidth: row.implicitWidth + 10
                implicitHeight: 30
                radius: 4
                color: Qt.darker(baseColor, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

                RowLayout {
                    id: row
                    anchors.centerIn: parent

                    IconImage {
                        implicitSize: 18
                        source: window.iconPath ? "file://" + window.iconPath : ""
                        visible: window.iconPath !== ""
                    }
                    Text {
                        text: _format(window.title, window.appId)
                        color: window.isFocused ? "#007aff" : "black"

                        function _format(title: string, appId: string): string {
                            if ((appId === "google-chrome")) {
                                return title.replace(/ - Google Chrome$/, "");
                            }
                            return title;
                        }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button == Qt.LeftButton)
                            Niri.focusWindow(window.id);
                        else if (mouse.button == Qt.RightButton)
                            Niri.toggleOverview();
                        else if (mouse.button == Qt.MiddleButton)
                            Niri.closeWindow(window.id);
                    }
                }
            }
        }
    }
}
