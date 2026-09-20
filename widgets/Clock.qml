pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    property bool showSeconds: false
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else if (mouse.button === Qt.RightButton) {
            showSeconds = !showSeconds;
            PopupManager.dismiss();
        }
    }
    content: Text {
        text: Qt.formatDateTime(Clock.date, `ddd MMM d  hh:mm${root.showSeconds ? ":ss" : ""}`)
    }

    Popup {
        id: popup
        property date displayedDate: Clock.date
        readonly property var locale: Qt.locale("en_GB")
        readonly property int dayCellSize: 28

        anchorItem: root
        onVisibleChanged: if (visible)
            displayedDate = Clock.date

        function shiftMonth(offset: int) {
            displayedDate = new Date(displayedDate.getFullYear(), displayedDate.getMonth() + offset, 1);
        }

        ColumnLayout {
            RowLayout {
                spacing: 4
                RowLayout {
                    spacing: 0
                    ShiftMonthButton {
                        offset: -1
                    }
                    HeaderText {
                        text: popup.locale.toString(popup.displayedDate, "MMMM")
                    }
                    ShiftMonthButton {
                        offset: 1
                    }
                }
                RowLayout {
                    spacing: 0
                    ShiftMonthButton {
                        offset: -12
                    }
                    HeaderText {
                        text: popup.displayedDate.getFullYear()
                    }
                    ShiftMonthButton {
                        offset: 12
                    }
                }
            }
            Controls.DayOfWeekRow {
                id: weekRow
                locale: popup.locale
                delegate: Text {
                    required property string shortName
                    width: popup.dayCellSize
                    font: weekRow.font
                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            Controls.MonthGrid {
                id: monthGrid
                locale: popup.locale
                month: popup.displayedDate.getMonth()
                year: popup.displayedDate.getFullYear()
                delegate: Rectangle {
                    id: cell
                    required property var model
                    implicitWidth: popup.dayCellSize
                    implicitHeight: popup.dayCellSize
                    radius: height / 2
                    color: model.today ? Theme.accent : "transparent"
                    opacity: model.month === monthGrid.month ? 1 : 0.35
                    Text {
                        anchors.centerIn: parent
                        color: cell.model.today ? Theme.textOnAccent : Theme.textPrimary
                        text: cell.model.day
                    }
                }
            }
        }
    }

    component ShiftMonthButton: Controls.ToolButton {
        required property int offset
        Layout.preferredWidth: 28
        Layout.preferredHeight: Layout.preferredWidth
        icon {
            name: `go-${offset < 0 ? "previous" : "next"}-symbolic`
            width: 10
            height: 10
        }
        onClicked: popup.shiftMonth(offset)
    }
    component HeaderText: Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 14
        font.weight: Font.Medium
        transform: Translate {
            y: -1.5
        }
    }
}
