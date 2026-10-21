import QtQuick
import Quickshell
import qs.components
import qs.config

Text {
    id: root
    property string url
    property alias tooltip: hint

    color: Theme.textPrimary
    font.underline: url !== "" && hint.hovered

    TapHandler {
        enabled: root.url !== ""
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.MiddleButton) {
                Quickshell.execDetached(["xdg-open", root.url]);
            } else {
                PopupHost.close();
                Qt.openUrlExternally(root.url);
            }
        }
    }

    Tooltip {
        id: hint
        anchorItem: root
        enabled: root.url !== "" || root.truncated
        cursorShape: root.url !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        text: (root.truncated ? root.text + "\n" : "") + root.url
    }
}
