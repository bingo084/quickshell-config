import QtQuick
import Quickshell
import qs.services

Text {
    required property ShellScreen screen
    text: Niri.title(screen.name)
}
