import QtQuick
import qs.services

Text {
    text: Qt.formatDateTime(Clock.date, "ddd, MMM dd, hh:mm:ss")
}
