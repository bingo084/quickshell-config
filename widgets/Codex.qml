pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    property date now: new Date()
    readonly property var windows: [Codex.rateLimits?.primary, Codex.rateLimits?.secondary]
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            PopupManager.dismiss();
            Qt.openUrlExternally("https://chatgpt.com/settings/usage");
        } else if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
            Codex.refresh(true);
        } else {
            popup.visible = !popup.visible;
        }
    }

    function remaining(window) {
        return window ? `${100 - window.usedPercent}%` : "--";
    }

    function meterColor(window) {
        if (window?.usedPercent >= 90)
            return Theme.critical;
        if (window?.usedPercent >= 75)
            return Theme.warning;
        return Theme.accent;
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

    content: RowLayout {
        spacing: 6
        Icon {
            id: codexIcon
            implicitSize: 18
            source: Qt.resolvedUrl("../assets/openai.svg")
            color: {
                if (root.windows.some(window => window?.usedPercent >= 100))
                    return Theme.critical;
                return Codex.error !== "" ? Theme.warning : Theme.textPrimary;
            }
            RotationAnimator {
                target: codexIcon
                from: 0
                to: 360
                duration: 1600
                loops: Animation.Infinite
                running: Codex.busy
                onStopped: codexIcon.rotation = 0
            }
        }
        ColumnLayout {
            spacing: 4
            Repeater {
                model: root.windows
                delegate: Rectangle {
                    id: summary
                    required property var modelData
                    implicitWidth: 36
                    implicitHeight: 3
                    radius: height / 2
                    color: Theme.meterBackground
                    opacity: modelData ? 1 : 0.4
                    Rectangle {
                        width: summary.modelData ? parent.width * (1 - summary.modelData.usedPercent / 100) : 0
                        height: parent.height
                        radius: parent.radius
                        color: root.meterColor(summary.modelData)
                    }
                }
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 280
        onVisibleChanged: {
            if (visible)
                Codex.refresh();
        }
        ColumnLayout {
            spacing: 10
            ColumnLayout {
                id: accountInfo
                readonly property string type: ({chatgpt: "ChatGPT", apiKey: "API key", amazonBedrock: "Amazon Bedrock"})[Codex.account?.type] ?? ""
                visible: Codex.account != null || Codex.provider != null
                spacing: 4
                RowLayout {
                    Text {
                        id: accountHeading
                        Layout.fillWidth: true
                        text: Codex.account?.email ?? Codex.provider?.name ?? accountMode.text
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: Theme.textPrimary
                    }
                    WrapperRectangle {
                        visible: plan.text !== ""
                        radius: 4
                        color: Theme.selectedBackground
                        margin: 2
                        leftMargin: 6
                        rightMargin: 6
                        Text {
                            id: plan
                            text: (Codex.account?.planType ?? "").replace(/_/g, " ")
                            font.capitalization: Font.Capitalize
                            font.pixelSize: 12
                            color: Theme.textOnSelected
                        }
                    }
                }
                RowLayout {
                    id: accountDetails
                    readonly property bool showAccountMode: accountMode.text !== "" && accountMode.text !== accountHeading.text
                    readonly property bool showResetCredits: Codex.account?.type === "chatgpt"
                    visible: showAccountMode || showResetCredits
                    Text {
                        id: accountMode
                        Layout.fillWidth: true
                        visible: accountDetails.showAccountMode
                        text: Codex.account?.email && Codex.provider ? Codex.provider.name : accountInfo.type
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                    Text {
                        id: resetSummary
                        visible: accountDetails.showResetCredits
                        text: `${Codex.resetCredits?.availableCount ?? "--"} resets available`
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: Codex.provider?.address ?? ""
                    wrapMode: Text.WrapAnywhere
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }
            Rectangle {
                Layout.fillWidth: true
                visible: (Codex.account != null || Codex.provider != null) && root.windows.some(Boolean)
                implicitHeight: 1
                color: Theme.popupBorder
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: Codex.error
                color: Theme.warning
                wrapMode: Text.Wrap
            }
            Repeater {
                model: root.windows.filter(Boolean)
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
                            color: detail.modelData.usedPercent >= 100 ? Theme.critical : Theme.textSecondary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: height / 2
                        color: Theme.meterBackground
                        Rectangle {
                            width: parent.width * (1 - detail.modelData.usedPercent / 100)
                            height: parent.height
                            radius: parent.radius
                            color: root.meterColor(detail.modelData)
                        }
                    }
                }
            }
        }
    }
}
