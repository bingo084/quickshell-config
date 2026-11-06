pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

Popup {
    id: root
    property bool showingHistory: false
    readonly property int count: showingHistory ? NotificationService.history.count : NotificationService.notifications.count
    readonly property real shadowMargin: 28
    readonly property var footer: list.footerItem
    readonly property var header: list.headerItem

    preferredWidth: 360 + 2 * shadowMargin
    contentMargin: 0
    topMargin: 0
    backgroundVisible: false
    regions: [region]
    onShowingHistoryChanged: Qt.callLater(list.positionViewAtBeginning)
    onVisibleChanged: {
        if (visible)
            showingHistory = false;
    }

    readonly property Region region: Region {
        regions: [root.header?.region, root.count > 0 ? root.cardRegions : root.footer?.region, root.viewportRegion].filter(Boolean)
    }
    readonly property Region cardRegions: Region {
        regions: Array.from(list.contentItem.children).filter(item => item instanceof NotificationRow).map(row => row.region).filter(Boolean)
    }
    readonly property Region viewportRegion: Region {
        item: list
        intersection: Intersection.Intersect
    }

    component NotificationRow: Item {
        id: row
        required property var model
        property var record: model.record ?? null
        property var entries: model.entries ?? null
        readonly property var view: loader.item
        readonly property Region region: view?.region ?? null
        width: list.width
        implicitHeight: loader.height
        // Keep the row's data alive through the ListView removal transition.
        Component.onCompleted: {
            record = model.record ?? null;
            entries = model.entries ?? null;
        }
        Loader {
            id: loader
            x: root.shadowMargin
            width: row.width - 2 * x
            sourceComponent: row.record ? historyCard : notificationGroup
        }
        Component {
            id: historyCard
            NotificationCard {
                record: row.record
                onActionInvoked: root.close()
            }
        }
        Component {
            id: notificationGroup
            NotificationGroup {
                entries: row.entries
                onActionInvoked: root.close()
            }
        }
    }

    ListView {
        id: list
        maximumHeight: PopupHost.height
        implicitHeight: Math.min(contentHeight + root.shadowMargin, maximumHeight)
        spacing: 10
        header: Item {
            readonly property Region region: Region {
                regions: [backButton.region, historyButton.region, clearButton.region]
            }

            width: list.width
            height: root.shadowMargin + toolbar.implicitHeight + 12
            RowLayout {
                id: toolbar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: root.shadowMargin
                y: root.shadowMargin
                spacing: 6

                NotificationButton {
                    id: backButton
                    size: 24
                    visible: root.showingHistory
                    iconName: "go-previous-symbolic"
                    tooltip.text: "Back to notifications"
                    onClicked: root.showingHistory = false
                }
                Text {
                    text: root.showingHistory ? "History" : "Notifications"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: "white"
                    style: Text.Outline
                    styleColor: "#40000000"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#99000000"
                        blurMax: 8
                        shadowBlur: 0.5
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 1
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                NotificationButton {
                    id: historyButton
                    size: 24
                    visible: !root.showingHistory
                    iconName: "document-open-recent-symbolic"
                    tooltip.text: "Notification history"
                    onClicked: root.showingHistory = true
                }
                DismissButton {
                    id: clearButton
                    visible: !root.showingHistory
                    enabled: NotificationService.notifications.count > 0
                    onClicked: NotificationService.clear()
                }
            }
        }
        footer: Item {
            readonly property Region region: Region {
                item: empty.visible ? empty : null
                radius: empty.radius
            }

            width: list.width
            height: empty.visible ? empty.implicitHeight : 0
            Rectangle {
                id: empty
                visible: root.count === 0
                x: root.shadowMargin
                width: list.width - 2 * root.shadowMargin
                height: implicitHeight
                implicitHeight: 160
                radius: 18
                color: Theme.background
                border.width: 1
                border.color: Theme.border
                Shadow {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -2
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        implicitSize: 28
                        name: "notification-symbolic"
                        color: Theme.textTertiary
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.showingHistory ? "No history yet" : "No notifications"
                        font.pixelSize: 13
                        color: Theme.textSecondary
                    }
                }
            }
        }
        Controls.ScrollBar.vertical: ScrollBar {
            viewport: list
            x: origin.x - (root.shadowMargin + width) / 2
        }
        onContentYChanged: root.region.changed()
        model: root.showingHistory ? NotificationService.history : NotificationService.groups
        delegate: NotificationRow {}
        populate: Transition {
            id: fadeIn
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        add: fadeIn
        addDisplaced: Transition {
            id: displace
            NumberAnimation {
                property: "y"
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        removeDisplaced: displace
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }
}
