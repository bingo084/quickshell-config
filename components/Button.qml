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
    property real size
    property string iconName
    readonly property var resolvedIcon: IconService.resolve(root.iconName)
    property alias radius: background.radius
    property alias tooltip: hint

    padding: size > 0 ? (size - icon.width) / 2 : 6
    opacity: enabled ? 1 : 0.5
    palette.buttonText: checked ? Theme.accent : variant === Button.Accent ? Theme.textOnAccent : Theme.textPrimary
    icon.color: palette.buttonText
    icon.width: 16
    icon.height: 16
    icon.name: resolvedIcon.name
    icon.source: resolvedIcon.source
    icon.cache: false

    Binding {
        target: root
        property: "icon.name"
        value: ""
        when: IconService.refreshing
    }

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
            const overlay = root.down ? Theme.pressOverlay : root.hovered ? Theme.hoverOverlay : "transparent";
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
            return root.variant === Button.Bordered ? Theme.border : "transparent";
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
