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
    readonly property bool waiting: Codex.waiting.length > 0
    readonly property int expiryLevel: Math.max(0, ...resetSection.credits.map(credit => root.creditLevel(credit)))

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            popup.closeAll();
            Qt.openUrlExternally("https://chatgpt.com/settings/usage");
        } else if (mouse.button === Qt.RightButton) {
            popup.closeOthers();
            Codex.refresh(true);
        } else {
            popup.toggle();
        }
    }

    function remaining(window) {
        return window ? `${100 - window.usedPercent}%` : "--";
    }

    function meterLevel(window): int {
        return window?.usedPercent >= 90 ? 2 : window?.usedPercent >= 75 ? 1 : 0;
    }

    function windowLabel(window) {
        const minutes = window.windowDurationMins;
        return ({
                300: "5-hour",
                10080: "Weekly"
            })[minutes] ?? (minutes == null ? "--" : `${minutes}m`);
    }

    function resetFraction(window: var): real {
        if (window?.resetsAt == null || !(window.windowDurationMins > 0))
            return -1;
        const remaining = window.resetsAt * 1000 - root.now.getTime();
        return Math.max(0, Math.min(1, remaining / (window.windowDurationMins * 60000)));
    }

    function creditLevel(credit: var): int {
        if (credit.expiresAt == null)
            return 0;
        const days = (credit.expiresAt * 1000 - root.now.getTime()) / (24 * 60 * 60 * 1000);
        if (days <= 0 || days > 3)
            return 0;
        return days <= 1 ? 2 : 1;
    }

    function expiryColor(level: int): color {
        return Theme.levelColor(level, Theme.textSecondary);
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
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    content: RowLayout {
        spacing: 6

        Icon {
            id: codexIcon
            name: "openai"
            spinning: Codex.busy && !root.waiting
            pulsing: root.waiting
            showBadge: root.waiting || root.expiryLevel > 0
            badgeColor: root.waiting ? Theme.warning : root.expiryColor(root.expiryLevel)
            color: {
                if (root.waiting)
                    return Theme.warning;
                if (root.windows.some(window => window?.usedPercent >= 100))
                    return Theme.critical;
                return Codex.error !== "" ? Theme.warning : Theme.textPrimary;
            }
            Tooltip {
                anchorItem: codexIcon
                enabled: root.expiryLevel > 0 && !root.waiting
                text: "Usage limit reset expires soon"
            }
        }

        ColumnLayout {
            spacing: 4

            Repeater {
                model: root.windows

                delegate: ProgressBar {
                    required property var modelData

                    implicitWidth: 36
                    implicitHeight: 2
                    opacity: modelData ? 1 : 0.4
                    value: modelData ? 1 - modelData.usedPercent / 100 : 0
                    level: root.meterLevel(modelData)
                    tickPosition: root.resetFraction(modelData)
                }
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 280
        onVisibleChanged: {
            if (visible) {
                root.now = new Date();
                Codex.refresh();
            }
        }

        ColumnLayout {
            spacing: 10

            ColumnLayout {
                id: accountInfo
                readonly property string type: ({
                        chatgpt: "ChatGPT",
                        apiKey: "API key",
                        amazonBedrock: "Amazon Bedrock"
                    })[Codex.account?.type] ?? ""
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

                Text {
                    id: accountMode
                    visible: text !== "" && text !== accountHeading.text && (Codex.account?.type !== "chatgpt" || Codex.provider != null)
                    text: Codex.account?.email && Codex.provider ? Codex.provider.name : accountInfo.type
                    font.pixelSize: 12
                    color: Theme.textSecondary
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

            Separator {
                visible: (Codex.account != null || Codex.provider != null) && (root.waiting || root.windows.some(Boolean))
            }

            Repeater {
                model: Codex.waiting

                delegate: RowLayout {
                    id: waitingThread
                    required property var modelData

                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: waitingThread.modelData.title
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Waiting for " + waitingThread.modelData.reasons.join(" & ")
                        font.pixelSize: 12
                        color: Theme.warning
                    }
                }
            }

            Separator {
                visible: root.waiting && root.windows.some(Boolean)
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

                    ProgressBar {
                        value: 1 - detail.modelData.usedPercent / 100
                        level: root.meterLevel(detail.modelData)
                        tickPosition: root.resetFraction(detail.modelData)
                        tickOverhang: 3
                    }
                }
            }

            Separator {
                visible: resetSection.visible && root.windows.some(Boolean)
            }

            ColumnLayout {
                id: resetSection
                property bool expanded: false
                readonly property var credits: (Codex.resetCredits?.credits ?? []).filter(credit => credit.status === "available")
                readonly property var groups: {
                    const groups = new Map();
                    for (const credit of credits) {
                        const title = credit.title ?? "";
                        if (!groups.has(title))
                            groups.set(title, []);
                        groups.get(title).push(credit);
                    }
                    return Array.from(groups, ([title, credits]) => ({
                                title,
                                credits
                            }));
                }
                Layout.fillWidth: true
                visible: Codex.resetCredits != null
                spacing: 6

                WrapperMouseArea {
                    id: resetArea
                    Layout.fillWidth: true
                    Layout.leftMargin: -4
                    Layout.rightMargin: -4
                    implicitHeight: 26
                    enabled: resetSection.credits.length > 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: resetSection.expanded = !resetSection.expanded

                    WrapperRectangle {
                        margin: 4
                        radius: 4
                        color: resetArea.pressed ? Theme.pressedBackground : resetArea.containsMouse ? Theme.hoveredBackground : "transparent"

                        RowLayout {
                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                text: "Usage limit resets"
                                font.pixelSize: 12
                                color: Theme.textPrimary
                            }
                            Text {
                                text: `${Codex.resetCredits?.availableCount ?? 0} available`
                                font.pixelSize: 12
                                color: root.expiryColor(root.expiryLevel)
                            }
                            Icon {
                                implicitSize: 12
                                visible: resetSection.credits.length > 0
                                color: Theme.textSecondary
                                name: resetSection.expanded ? "pan-down-symbolic" : "pan-end-symbolic"
                            }
                        }
                    }
                }

                Repeater {
                    model: resetSection.groups

                    delegate: ColumnLayout {
                        id: creditGroup
                        required property var modelData

                        visible: resetSection.expanded
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: creditGroup.modelData.title
                            font.pixelSize: 12
                            color: Theme.textPrimary
                            wrapMode: Text.Wrap
                        }

                        Repeater {
                            model: creditGroup.modelData.credits

                            delegate: RowLayout {
                                id: creditRow
                                required property var modelData
                                readonly property int expiryLevel: root.creditLevel(modelData)

                                Text {
                                    Layout.fillWidth: true
                                    text: creditRow.modelData.expiresAt == null ? "No expiration" : creditRow.expiryLevel > 0 ? "Expires soon" : "Expires"
                                    font.pixelSize: 12
                                    color: root.expiryColor(creditRow.expiryLevel)
                                }
                                Text {
                                    text: creditRow.modelData.expiresAt == null ? "" : Qt.formatDateTime(new Date(creditRow.modelData.expiresAt * 1000), "MMM d  hh:mm")
                                    font.pixelSize: 12
                                    color: root.expiryColor(creditRow.expiryLevel)
                                }

                                Tooltip {
                                    anchorItem: creditRow
                                    text: creditRow.modelData.description ?? ""
                                    enabled: text !== ""
                                }
                            }
                        }
                    }
                }
            }

            RefreshControl {
                Layout.alignment: Qt.AlignRight
                updatedAt: Codex.updatedAt
                refreshing: Codex.refreshing
                enabled: Codex.connected
                onRefreshRequested: Codex.refresh(true)
            }
        }
    }
}
