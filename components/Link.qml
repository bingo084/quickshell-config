import QtQuick
import qs.config

Text {
    id: root
    property string url
    property alias tooltip: hint
    signal clicked()

    color: Theme.textPrimary
    font.underline: url !== "" && hint.hovered

    TapHandler {
        enabled: root.url !== ""
        onTapped: root.clicked()
    }

    Tooltip {
        id: hint
        anchorItem: root
        enabled: root.url !== "" || root.truncated
        cursorShape: root.url !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        text: (root.truncated ? root.text + "\n" : "") + root.url
    }
}
