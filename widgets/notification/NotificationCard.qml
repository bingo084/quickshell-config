pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.config

Button {
    id: root
    required property var popup
    readonly property Notification notification: popup.notification
    readonly property var defaultAction: Array.from(notification.actions).find(action => action.identifier === "default")
    readonly property var actions: Array.from(notification.actions).filter(action => action.identifier !== "default")
    readonly property bool expandable: summary.truncated || body.truncated || actions.length > 0
    readonly property real timeout: notification.urgency === NotificationUrgency.Critical || notification.expireTimeout === 0 ? 0 : notification.expireTimeout < 0 ? 6000 : notification.expireTimeout
    signal finished
    property bool expanded: false
    readonly property Region region: Region {
        item: root
        radius: plate.radius
    }

    height: implicitHeight
    Behavior on height {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    padding: 14
    opacity: 1
    enabled: !popup.closing
    cursorShape: defaultAction || expandable || expanded ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
        if (defaultAction)
            defaultAction.invoke();
        else if (expandable || expanded)
            expanded = !expanded;
    }
    Component.onCompleted: {
        if (popup.closing)
            exit.start();
        else
            entrance.start();
    }

    Connections {
        target: root.popup
        function onClosingChanged() {
            if (root.popup.closing) {
                entrance.stop();
                exit.start();
            }
        }
        function onRefreshed() {
            root.expanded = false;
            if (root.timeout > 0 && !root.hovered && !root.popup.closing)
                hideTimer.restart();
            else
                hideTimer.stop();
        }
    }

    Timer {
        id: hideTimer
        interval: Math.max(1, root.timeout)
        running: root.timeout > 0 && !root.hovered && !root.expanded && !root.popup.closing
        onTriggered: root.notification.expire()
    }

    ParallelAnimation {
        id: entrance
        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "x"
            from: 18
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    ParallelAnimation {
        id: exit
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "x"
            to: 18
            duration: 160
            easing.type: Easing.OutCubic
        }
        onFinished: root.finished()
    }

    Shadow {
        anchors.fill: plate
        radius: plate.radius
        z: -2
    }
    background: Rectangle {
        id: plate
        color: Theme.background
        radius: 18
        border.width: 1
        border.color: Theme.border
    }

    contentItem: Item {
        implicitHeight: content.implicitHeight
        clip: true

        RowLayout {
            id: content
            width: parent.width
            height: implicitHeight
            spacing: 12

            Icon {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: {
                    let textHeight = header.y + header.implicitHeight;
                    if (summary.visible)
                        textHeight += textColumn.spacing + summary.collapsedHeight;
                    if (body.visible)
                        textHeight += textColumn.spacing + body.collapsedHeight;
                    return Math.max(0, (textHeight - implicitHeight) / 2);
                }
                implicitSize: 40
                name: root.notification.appIcon || "dialog-information-symbolic"
                source: root.notification.image || (root.notification.appIcon.startsWith("/") ? "file://" + root.notification.appIcon : root.notification.appIcon.includes("://") ? root.notification.appIcon : "")
                theme: "hicolor"
                color: root.notification.appIcon || root.notification.image ? "transparent" : Theme.textSecondary
            }
            ColumnLayout {
                id: textColumn
                Layout.fillWidth: true
                spacing: 2

                Text {
                    visible: root.notification.urgency === NotificationUrgency.Critical
                    text: "重要通知"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                }
                RowLayout {
                    id: header
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: root.notification.appName
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Qt.formatTime(root.popup.receivedAt, "HH:mm")
                        font.pixelSize: 10
                        color: Theme.textTertiary
                    }
                    Button {
                        visible: root.expandable || root.expanded
                        size: 18
                        icon.width: 12
                        icon.height: 12
                        iconName: root.expanded ? "pan-up-symbolic" : "pan-down-symbolic"
                        icon.color: Theme.textSecondary
                        opacity: root.hovered || root.expanded ? 1 : 0
                        onClicked: root.expanded = !root.expanded
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                    Button {
                        size: 18
                        icon.width: 12
                        icon.height: 12
                        iconName: "window-close-symbolic"
                        icon.color: Theme.textSecondary
                        opacity: root.hovered || root.down ? 1 : 0
                        onClicked: root.notification.dismiss()
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                }
                ExpandableText {
                    id: summary
                    text: root.notification.summary
                    font.weight: Font.DemiBold
                    expanded: root.expanded
                }
                ExpandableText {
                    id: body
                    text: root.notification.body
                    expanded: root.expanded
                }
                Item {
                    Layout.fillWidth: true
                    visible: root.actions.length > 0
                    implicitHeight: root.expanded ? actionRow.implicitHeight + 8 : 0

                    RowLayout {
                        id: actionRow
                        width: parent.width
                        y: 8
                        opacity: root.expanded ? 1 : 0
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
                                required property NotificationAction modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: modelData.text
                                font.pixelSize: 12
                                verticalPadding: 4
                                variant: Button.Filled
                                onClicked: modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    component ExpandableText: Item {
        id: textBlock
        property alias text: preview.text
        property alias font: preview.font
        property bool expanded
        readonly property alias truncated: preview.truncated
        readonly property real collapsedHeight: preview.implicitHeight

        Layout.fillWidth: true
        visible: text.trim() !== ""
        implicitHeight: expanded ? fullText.implicitHeight : collapsedHeight

        Text {
            id: preview
            width: parent.width
            textFormat: Text.PlainText
            font.pixelSize: 13
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: !textBlock.expanded
        }
        Text {
            id: fullText
            width: parent.width
            text: textBlock.text
            textFormat: Text.PlainText
            font: textBlock.font
            color: preview.color
            wrapMode: Text.Wrap
            visible: textBlock.expanded
        }
    }
}
