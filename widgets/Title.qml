pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Repeater {
    id: root
    required property ShellScreen screen
    model: Niri.workspaces

    Repeater {
        id: workspace
        required property int activeWindowId
        required property bool isActive
        required property string output
        model: isActive && output === root.screen.name ? Niri.windows : 0

        Text {
            required property int id
            required property string title
            text: title
            visible: workspace.activeWindowId === id
        }
    }
}
