import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen

    spacing: 4
    visible: root.screen.name === "eDP-1" && Brightness.available

    IconImage {
        implicitSize: 18
        source: Quickshell.iconPath("display-brightness-symbolic")
    }
    Text {
        color: Theme.textPrimary
        text: Math.round(Brightness.level * 100) + "%"
    }
}
