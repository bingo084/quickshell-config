pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.components.bar
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
        anchorItem: root
        ColumnLayout {
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: monthGrid.title
            }
            Controls.DayOfWeekRow {
                locale: monthGrid.locale
                delegate: Text {
                    required property string shortName
                    width: 28
                    height: 24
                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Controls.MonthGrid {
                id: monthGrid
                locale: Qt.locale("en_GB")
                month: Clock.date.getMonth()
                year: Clock.date.getFullYear()
                delegate: Rectangle {
                    id: cell
                    required property var model
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: height / 2
                    color: model.today ? "#007aff" : "transparent"
                    opacity: model.month === monthGrid.month ? 1 : 0.35
                    Text {
                        anchors.centerIn: parent
                        color: cell.model.today ? "white" : "black"
                        text: cell.model.day
                    }
                }
            }
        }
    }
}
