import QtQuick
import Quickshell.Wayland

Text {
    text: ToplevelManager.activeToplevel?.title ?? ""
}
