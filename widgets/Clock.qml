pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarButton {
    id: root
    property bool showSeconds

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else if (mouse.button === Qt.RightButton) {
            showSeconds = !showSeconds;
            popup.closeAll();
        }
    }

    content: Text {
        color: Theme.textPrimary
        text: Qt.formatDateTime(ClockService.date, `ddd ${ClockService.dateTimeFormat}${root.showSeconds ? ":ss" : ""}`)
    }

    Popup {
        id: popup
        property date displayedDate: ClockService.date
        property date selectedDate: ClockService.date
        property bool choosingMonth
        readonly property int controlSize: 32
        readonly property var locale: Qt.locale("en_GB")
        readonly property bool showingCurrentMonth: displayedDate.getFullYear() === ClockService.date.getFullYear() && displayedDate.getMonth() === ClockService.date.getMonth()

        anchorItem: root
        contentWidth: 294
        onVisibleChanged: if (visible)
            reset()

        function shift(offset: int) {
            const months = offset * (choosingMonth ? 12 : 1);
            displayedDate = new Date(displayedDate.getFullYear(), displayedDate.getMonth() + months, 1);
        }
        function chooseMonth(month: int) {
            displayedDate = new Date(displayedDate.getFullYear(), month, 1);
            choosingMonth = false;
        }
        function reset() {
            selectedDate = ClockService.date;
            displayedDate = ClockService.date;
            choosingMonth = false;
        }

        ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 4
                Button {
                    id: headingButton
                    Layout.fillWidth: true
                    leftPadding: 10
                    text: popup.choosingMonth ? String(popup.displayedDate.getFullYear()) : popup.locale.toString(popup.displayedDate, "MMMM yyyy")
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    onClicked: popup.choosingMonth = !popup.choosingMonth
                    tooltip.text: popup.choosingMonth ? "Back to calendar" : "Choose month and year"
                    contentItem: Text {
                        text: headingButton.text
                        font: headingButton.font
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Button {
                    size: popup.controlSize
                    radius: height / 2
                    iconName: "calendar-today-symbolic"
                    enabled: popup.choosingMonth || !popup.showingCurrentMonth || popup.selectedDate.toDateString() !== ClockService.date.toDateString()
                    onClicked: popup.reset()
                    tooltip.text: "Today"
                }
                Button {
                    size: popup.controlSize
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    onClicked: popup.shift(-1)
                    tooltip.text: popup.choosingMonth ? "Previous year" : "Previous month"
                }
                Button {
                    size: popup.controlSize
                    radius: height / 2
                    iconName: "go-next-symbolic"
                    onClicked: popup.shift(1)
                    tooltip.text: popup.choosingMonth ? "Next year" : "Next month"
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                implicitHeight: 252

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4
                    visible: !popup.choosingMonth
                    DayOfWeekRow {
                        Layout.fillWidth: true
                        locale: popup.locale
                        spacing: 2
                        delegate: Text {
                            required property string shortName
                            text: shortName
                            font.pixelSize: 12
                            color: Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MonthGrid {
                        id: calendar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        locale: popup.locale
                        spacing: 2
                        month: popup.displayedDate.getMonth()
                        year: popup.displayedDate.getFullYear()
                        onClicked: date => {
                            popup.selectedDate = date;
                            popup.displayedDate = date;
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        delegate: Item {
                            id: cell
                            required property var model
                            readonly property bool selected: model.date.toDateString() === popup.selectedDate.toDateString()
                            opacity: model.month === calendar.month ? 1 : 0.35
                            Rectangle {
                                anchors.centerIn: parent
                                width: popup.controlSize
                                height: width
                                radius: width / 2
                                color: cell.model.today ? Theme.accent : "transparent"
                                border.width: cell.selected && !cell.model.today ? 1 : 0
                                border.color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                text: cell.model.day
                                color: cell.model.today ? Theme.textOnAccent : Theme.textPrimary
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                GridLayout {
                    anchors.fill: parent
                    visible: popup.choosingMonth
                    columns: 3
                    uniformCellWidths: true
                    columnSpacing: 6
                    rowSpacing: 6
                    Repeater {
                        model: 12
                        delegate: Button {
                            required property int index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: popup.locale.standaloneMonthName(index, Locale.ShortFormat)
                            font.pixelSize: 13
                            checked: index === popup.displayedDate.getMonth()
                            onClicked: popup.chooseMonth(index)
                        }
                    }
                }
            }
        }
    }
}
