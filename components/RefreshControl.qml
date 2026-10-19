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
    spacing: 4

    Text {
        id: updatedLabel
        visible: text !== ""
        color: Theme.textTertiary
        font.pixelSize: 11
        text: {
            if (root.updatedAt == null)
                return "";
            const today = root.updatedAt.toDateString() === Clock.date.toDateString();
            return (root.chinese ? "刷新于  " : "Refreshed  ") + Qt.formatDateTime(root.updatedAt, today ? Clock.timeFormat : Clock.dateTimeFormat);
        }
    }

    Button {
        text: root.chinese ? "刷新" : "Refresh"
        enabled: !root.refreshing
        onClicked: root.refreshRequested()

        contentItem: Icon {
            implicitSize: 14
            name: "emblem-synchronizing-symbolic"
            color: Theme.textSecondary
            spinning: root.refreshing
        }

        tooltip.text: text
    }

    Tooltip {
        anchorItem: updatedLabel
        text: root.updatedAt == null ? "" : (root.chinese ? "上次刷新：" : "Last refreshed: ") + Qt.formatDateTime(root.updatedAt, Clock.fullDateTimeFormat)
    }
}
