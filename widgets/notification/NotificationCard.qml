pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.config
import qs.services

Button {
    id: root
    required property var record
    property int stackCount: 1
    property bool backgroundVisible: true
    property bool expanded: false
    property bool completed: false
    readonly property real expandOffset: 2
    readonly property var snapshot: record.snapshot
    readonly property var defaultAction: record.actions.find(action => action.identifier === "default")
    readonly property var actions: record.actions.filter(action => action.identifier !== "default" || action.text.trim() !== "")
    readonly property bool expandable: stackCount === 1 && (expanded || summary.truncated || body.truncated || actions.length > 0)
    readonly property bool hovering: hovered || closeButton.hovered || closeButton.down
    readonly property Region region: Region {
        regions: [cardRegion, closeButton.region]
    }
    signal dismissRequested(bool group)
    signal actionInvoked

    padding: 14
    rightPadding: padding - expandOffset
    height: implicitHeight
    onClicked: {
        if (stackCount > 1)
            toggleExpanded();
        else
            activate();
    }
    Component.onCompleted: {
        record.viewers++;
        completed = true;
    }
    Component.onDestruction: {
        if (record) {
            record.viewers--;
            Qt.callLater(record.release);
        }
    }
    Behavior on height {
        enabled: root.completed
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    function activate(action = defaultAction) {
        if (NotificationService.activate(record, action))
            actionInvoked();
    }

    function toggleExpanded() {
        expanded = !expanded;
    }

    function formatTime(date: date): string {
        const minutes = Math.max(0, Math.floor((ClockService.date - date) / 60000));
        if (minutes < 1)
            return "Now";
        if (minutes < 60)
            return `${minutes}m`;
        if (minutes < 1440)
            return `${Math.floor(minutes / 60)}h`;
        if (minutes < 10080)
            return `${Math.floor(minutes / 1440)}d`;
        return Qt.formatDate(date, "MMM d");
    }

    Region {
        id: cardRegion
        item: root
        radius: plate.radius
    }
    Shadow {
        anchors.fill: plate
        radius: plate.radius
        z: -2
    }
    background: Rectangle {
        id: plate
        color: root.backgroundVisible ? Theme.background : "transparent"
        radius: 18
        border.width: root.backgroundVisible ? 1 : 0
        border.color: Theme.border
    }

    DismissButton {
        id: closeButton
        expandable: root.stackCount > 1
        visible: root.record.active
        x: root.width - width + 5
        y: -5
        z: 1
        opacity: root.hovering ? 1 : 0
        enabled: opacity > 0
        onClicked: root.dismissRequested(root.stackCount > 1)
        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Item {
        implicitHeight: message.implicitHeight + (root.expanded && root.actions.length > 0 ? actionRow.implicitHeight + 8 : 0)
        clip: true
        RowLayout {
            id: message
            width: parent.width - root.expandOffset
            height: implicitHeight
            spacing: 12
            Behavior on height {
                enabled: root.completed
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            Icon {
                id: appIcon
                implicitSize: 36
                name: root.snapshot.appIcon || "dialog-information-symbolic"
                source: root.record.image || (root.snapshot.appIcon.startsWith("/") ? "file://" + root.snapshot.appIcon : root.snapshot.appIcon.includes("://") ? root.snapshot.appIcon : "")
                theme: "hicolor"
                color: root.snapshot.appIcon || root.record.image ? "transparent" : Theme.textSecondary
                Tooltip {
                    anchorItem: appIcon
                    text: root.snapshot.appName
                    enabled: text !== ""
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: 0
                Layout.alignment: Qt.AlignTop
                spacing: 2
                Text {
                    visible: root.snapshot.urgency === NotificationUrgency.Critical
                    text: "Urgent notification"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    NotificationText {
                        id: summary
                        text: root.snapshot.summary || root.snapshot.appName
                        font.weight: Font.DemiBold
                        previewLines: body.visible ? 2 : 3
                        expanded: root.expanded
                    }
                    Button {
                        id: timeButton
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: Math.max(implicitHeight, Math.ceil(timeMetrics.advanceWidth))
                        implicitHeight: 24
                        padding: 0
                        leftPadding: display === Button.IconOnly ? width - height : Math.max(0, width - implicitContentWidth)
                        leftInset: width - height
                        text: root.formatTime(root.record.receivedAt)
                        font.pixelSize: 10
                        palette.buttonText: Theme.textTertiary
                        icon.width: 14
                        icon.height: 14
                        iconName: root.expanded ? "pan-up-symbolic" : "pan-end-symbolic"
                        icon.color: Theme.textSecondary
                        display: root.expandable && (root.hovering || hovered || visualFocus) ? Button.IconOnly : Button.TextOnly
                        hoverEnabled: root.expandable
                        cursorShape: root.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        tooltip.text: Qt.formatDateTime(root.record.receivedAt, ClockService.fullDateTimeFormat)
                        transform: Translate {
                            x: timeButton.display === Button.IconOnly ? root.expandOffset : 0
                        }
                        onClicked: {
                            if (root.expandable)
                                root.toggleExpanded();
                        }
                        TextMetrics {
                            id: timeMetrics
                            font: timeButton.font
                            text: timeButton.text
                        }
                    }
                }
                NotificationText {
                    id: body
                    text: root.snapshot.body
                    expanded: root.expanded
                }
            }
        }
        RowLayout {
            id: actionRow
            anchors.right: parent.right
            anchors.rightMargin: root.expandOffset
            y: message.height + 8
            width: root.actions.length <= 2 ? Math.min(implicitWidth, message.width) : message.width
            opacity: root.expanded && root.actions.length > 0 ? 1 : 0
            visible: opacity > 0
            enabled: root.expanded
            spacing: 6
            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }
            Repeater {
                model: root.actions
                Button {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.actions.length <= 2 ? implicitWidth : 1
                    Layout.minimumWidth: root.actions.length <= 2 ? 96 : 0
                    text: modelData.text
                    font.pixelSize: 12
                    leftPadding: 12
                    rightPadding: leftPadding
                    verticalPadding: 4
                    variant: Button.Filled
                    onClicked: root.activate(modelData)
                }
            }
        }
    }
}
