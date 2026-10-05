import QtQuick
import QtQuick.Controls as Controls
import qs.config

Controls.Button {
    id: root
    padding: 6
    opacity: enabled ? 1 : 0.5
    palette.buttonText: checked ? Theme.textOnSelected : Theme.textPrimary
    icon.color: palette.buttonText
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
    }
}
