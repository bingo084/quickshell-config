import QtQuick
import QtQuick.Controls as Controls
import qs.config
import qs.services

Controls.Button {
    id: root
    property string iconName

    padding: 6
    opacity: enabled ? 1 : 0.5
    palette.buttonText: checked ? Theme.textOnSelected : Theme.textPrimary
    icon.color: palette.buttonText
    icon.source: Icons.source(root.iconName)

    Behavior on palette.buttonText {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        radius: 5
        color: {
            const overlay = root.down ? Theme.pressedBackground : root.hovered ? Theme.hoveredBackground : "transparent";
            if (root.checked)
                return Qt.tint(Theme.selectedBackground, overlay);
            return root.flat ? overlay : Qt.tint(Theme.controlBackground, overlay);
        }

        border.color: {
            if (root.visualFocus || root.checked)
                return Theme.accent;
            if (root.flat && !root.hovered)
                return "transparent";
            return Theme.popupBorder;
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }
}
