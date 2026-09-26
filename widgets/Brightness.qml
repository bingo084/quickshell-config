import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components.bar
import qs.services

Button {
    id: root
    required property ShellScreen screen
    visible: root.screen.name === "eDP-1" && Brightness.available
    onClicked: popup.visible = !popup.visible
    onWheel: event => {
        if (event.angleDelta.y > 0) {
            Brightness.change(1);
        } else if (event.angleDelta.y < 0) {
            Brightness.change(-1);
        }
    }
    content: RowLayout {
        spacing: 4
        IconImage {
            implicitSize: 18
            source: Quickshell.iconPath("display-brightness-symbolic")
        }
        Text {
            color: Theme.textPrimary
            text: Math.round(Brightness.level * 100) + "%"
        }
    }
    Popup {
        id: popup
        anchorItem: root
        content: Slider {
            value: Brightness.level
            onMoved: Brightness.setLevel(value)
        }
    }
}
