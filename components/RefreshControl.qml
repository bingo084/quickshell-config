import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    property var updatedAt
    property bool refreshing
    property bool chinese
    signal refreshRequested
    spacing: 2

    Text {
        id: updatedLabel
        visible: text !== ""
        color: Theme.textTertiary
        font.pixelSize: 11
        text: {
            if (root.updatedAt == null)
                return "";
            const today = root.updatedAt.toDateString() === Clock.date.toDateString();
            return (root.chinese ? "更新于 " : "Updated ") + Qt.formatDateTime(root.updatedAt, today ? "hh:mm" : "MMM d  hh:mm");
        }

        HoverHandler {
            id: hover
        }
    }

    Button {
        flat: true
        enabled: !root.refreshing
        onClicked: root.refreshRequested()

        contentItem: Icon {
            id: refreshIcon
            implicitSize: 14
            name: "emblem-synchronizing-symbolic"
            color: Theme.textSecondary

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 1300
                loops: Animation.Infinite
                running: root.refreshing
                onStopped: refreshIcon.rotation = 0
            }
        }
    }

    Tooltip {
        anchorItem: updatedLabel
        active: hover.hovered
        text: root.updatedAt == null ? "" : (root.chinese ? "上次更新：" : "Last updated: ") + Qt.formatDateTime(root.updatedAt, "yyyy-MM-dd hh:mm:ss")
    }
}
