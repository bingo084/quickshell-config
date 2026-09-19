pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen
    spacing: 0

    Repeater {
        model: Niri.workspaces

        Rectangle {
            id: workspace
            required property var model
            readonly property int _id: model.id
            required property int index
            required property bool isActive
            required property string output
            readonly property color baseColor: isActive ? "#eeeeee" : "#ffffff"
            visible: output === root.screen.name
            implicitWidth: 32
            implicitHeight: 30
            radius: 4
            color: Qt.darker(baseColor, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

            Text {
                anchors.centerIn: parent
                text: workspace.index
                color: workspace.isActive ? "#007aff" : "black"
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    BarPopupManager.dismiss();
                    Niri.focusWorkspaceById(workspace._id);
                }
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y;
                    if (delta === 0)
                        return;
                    const workspaces = Niri.workspaces;
                    let active = null;
                    for (let row = 0; row < workspaces.count; row++) {
                        const ws = workspaces.get(row);
                        if (ws.output === root.screen.name && ws.isActive) {
                            active = ws;
                            break;
                        }
                    }
                    if (active === null)
                        return;
                    const targetIndex = active.index + (delta > 0 ? -1 : 1);
                    for (let row = 0; row < workspaces.count; row++) {
                        const ws = workspaces.get(row);
                        if (ws.output === root.screen.name && ws.index === targetIndex) {
                            Niri.focusWorkspaceById(ws.id);
                            break;
                        }
                    }
                }
            }
        }
    }
}
