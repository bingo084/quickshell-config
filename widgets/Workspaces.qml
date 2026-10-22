pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen

    spacing: 0

    Repeater {
        model: NiriService.workspaces

        Rectangle {
            id: workspace
            required property var model
            readonly property int _id: model.id
            required property int index
            required property bool isActive
            required property string output
            readonly property color overlayColor: area.pressed ? Theme.pressedBackground : area.containsMouse ? Theme.hoveredBackground : "transparent"

            visible: output === root.screen?.name
            implicitWidth: 32
            implicitHeight: 30
            radius: 4
            color: isActive ? Qt.tint(Theme.selectedBackground, overlayColor) : overlayColor
            border.width: isActive ? 1 : 0
            border.color: Theme.popupBorder
            Text {
                anchors.centerIn: parent
                text: workspace.index
                color: Theme.textPrimary
                font.weight: workspace.isActive ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    PopupHost.close();
                    NiriService.focusWorkspaceById(workspace._id);
                }
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y;
                    if (delta === 0)
                        return;
                    const workspaces = NiriService.workspaces;
                    let active = null;
                    for (let row = 0; row < workspaces.count; row++) {
                        const ws = workspaces.get(row);
                        if (ws.output === root.screen?.name && ws.isActive) {
                            active = ws;
                            break;
                        }
                    }
                    if (active === null)
                        return;
                    const targetIndex = active.index + (delta > 0 ? -1 : 1);
                    for (let row = 0; row < workspaces.count; row++) {
                        const ws = workspaces.get(row);
                        if (ws.output === root.screen?.name && ws.index === targetIndex) {
                            NiriService.focusWorkspaceById(ws.id);
                            break;
                        }
                    }
                }
            }
        }
    }
}
