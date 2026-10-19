import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.config

Controls.TextField {
    id: root
    property bool password

    Layout.fillWidth: true
    padding: 6
    leftPadding: 12
    rightPadding: leftPadding + (password ? revealButton.width : 0)
    font.pixelSize: 13
    color: Theme.textPrimary
    placeholderTextColor: Theme.textSecondary
    echoMode: password && !revealButton.revealed ? TextInput.Password : TextInput.Normal

    Button {
        id: revealButton
        property bool revealed

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.password
        width: 32
        height: 32
        iconName: revealed ? "view-conceal-symbolic" : "view-reveal-symbolic"
        onClicked: {
            revealed = !revealed;
            root.forceActiveFocus();
        }

        Tooltip {
            anchorItem: revealButton
            text: revealButton.revealed ? "Hide password" : "Show password"
        }
    }

    background: Rectangle {
        implicitHeight: 32
        radius: 5
        color: Theme.controlBackground
        border.color: root.activeFocus ? Theme.accent : Theme.popupBorder
    }
}
