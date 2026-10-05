import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.components.bar
import qs.services

Button {
    id: root
    required property ShellScreen screen
    visible: Brightness.available && root.screen?.name === Brightness.output
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
        Icon {
            readonly property string strength: Brightness.level < 1 / 3 ? "low" : Brightness.level < 2 / 3 ? "medium" : "high"
            implicitSize: 16
            source: Quickshell.iconPath(`display-brightness-${strength}-symbolic`, "display-brightness-symbolic")
        }
        Text {
            color: Theme.textPrimary
            text: Math.round(Brightness.level * 100) + "%"
        }
    }
    Popup {
        id: popup
        anchorItem: root
        content: Controls.Slider {
            from: Brightness.minimumLevel
            value: Brightness.level
            onMoved: Brightness.setLevel(value)
        }
    }
}
