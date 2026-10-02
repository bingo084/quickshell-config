pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    property date now: new Date()
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
            CodexQuota.refresh(true);
        } else {
            popup.visible = !popup.visible;
            if (popup.visible)
                CodexQuota.refresh();
        }
    }

    function remaining(window) {
        return window ? `${100 - window.usedPercent}%` : "--";
    }

    function windowLabel(window) {
        const minutes = window.windowDurationMins;
        return ({
                300: "5-hour",
                10080: "Weekly"
            })[minutes] ?? (minutes == null ? "--" : `${minutes}m`);
    }

    function resetText(window) {
        if (window.resetsAt == null)
            return "Resets: --";
        const resetAt = new Date(window.resetsAt * 1000);
        const time = Qt.formatDateTime(resetAt, resetAt.toDateString() === root.now.toDateString() ? "hh:mm" : "MMM d  hh:mm");
        const totalMinutes = Math.ceil((resetAt.getTime() - root.now.getTime()) / 60000);
        if (totalMinutes <= 0)
            return `Reset pending · ${time}`;
        const days = Math.floor(totalMinutes / 1440);
        const hours = Math.floor(totalMinutes % 1440 / 60);
        const minutes = totalMinutes % 60;
        const parts = [];
        if (days > 0)
            parts.push(`${days}d`);
        if (hours > 0)
            parts.push(`${hours}h`);
        if (minutes > 0)
            parts.push(`${minutes}m`);
        return `Resets in ${parts.slice(0, 2).join(" ")} · ${time}`;
    }

    Timer {
        interval: 60000
        running: popup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    content: Text {
        color: CodexQuota.error !== "" ? Theme.warning : Theme.textPrimary
        text: {
            const limits = CodexQuota.data?.rateLimits;
            return `Codex ${root.remaining(limits?.primary)} / ${root.remaining(limits?.secondary)}`;
        }
    }

    Popup {
        id: popup
        anchorItem: root
        ColumnLayout {
            spacing: 10
            Text {
                Layout.preferredWidth: 280
                visible: text !== ""
                text: CodexQuota.error
                color: Theme.warning
                wrapMode: Text.Wrap
            }
            Repeater {
                model: [CodexQuota.data?.rateLimits?.primary, CodexQuota.data?.rateLimits?.secondary].filter(Boolean)
                delegate: ColumnLayout {
                    id: detail
                    required property var modelData
                    spacing: 4
                    Text {
                        text: `${root.windowLabel(detail.modelData)} limit`
                        font.weight: Font.Medium
                        font.styleName: ""
                        color: Theme.textPrimary
                    }
                    RowLayout {
                        Text {
                            Layout.fillWidth: true
                            text: root.resetText(detail.modelData)
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                        Text {
                            text: `${root.remaining(detail.modelData)} left`
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 280
                        implicitHeight: 4
                        radius: height / 2
                        color: Theme.meterBackground
                        Rectangle {
                            width: parent.width * (1 - detail.modelData.usedPercent / 100)
                            height: parent.height
                            radius: parent.radius
                            color: {
                                if (detail.modelData.usedPercent >= 90)
                                    return Theme.critical;
                                if (detail.modelData.usedPercent >= 75)
                                    return Theme.warning;
                                return Theme.accent;
                            }
                        }
                    }
                }
            }
        }
    }
}
