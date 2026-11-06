pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config

Text {
    property bool expanded
    property int previewLines: 2

    Layout.fillWidth: true
    visible: text.trim() !== ""
    textFormat: Text.PlainText
    font.pixelSize: 13
    color: Theme.textPrimary
    wrapMode: Text.Wrap
    maximumLineCount: expanded ? undefined : previewLines
    elide: expanded ? Text.ElideNone : Text.ElideRight
}
