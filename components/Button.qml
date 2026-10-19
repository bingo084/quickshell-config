import QtQuick
import QtQuick.Controls as Controls
import qs.config
import qs.services

Controls.Button {
    id: root
    enum Variant {
        Accent,
        Bordered,
        Filled,
        Plain
    }

    property int variant: Button.Plain
    property string iconName
    property alias radius: background.radius
    property alias tooltip: hint

    padding: 6
    opacity: enabled ? 1 : 0.5
    palette.buttonText: checked ? Theme.textOnSelected : variant === Button.Accent ? Theme.textOnAccent : Theme.textPrimary
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

    Tooltip {
        id: hint
        anchorItem: root
        enabled: text !== ""
    }

    background: Rectangle {
        id: background
        radius: 5
        color: {
            const overlay = root.down ? Theme.pressedBackground : root.hovered ? Theme.hoveredBackground : "transparent";
            if (root.checked)
                return Qt.tint(Theme.selectedBackground, overlay);
            switch (root.variant) {
            case Button.Accent:
                return Qt.tint(Theme.accent, overlay);
            case Button.Bordered:
            case Button.Filled:
                return Qt.tint(Theme.controlBackground, overlay);
            default:
                return overlay;
            }
        }

        border.color: {
            if (root.visualFocus)
                return root.variant === Button.Accent && !root.checked ? Theme.textOnAccent : Theme.accent;
            if (root.checked)
                return Theme.accent;
            return root.variant === Button.Bordered ? Theme.popupBorder : "transparent";
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
