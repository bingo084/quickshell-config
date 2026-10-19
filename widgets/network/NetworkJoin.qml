import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as Net
import qs.components
import qs.config
import qs.services

// qmllint disable unresolved-type
ColumnLayout {
    id: root
    required property Net.WifiNetwork network
    property bool hidden
    property bool busy
    property bool opened
    property string error
    readonly property bool validPassword: hidden || Network.validPassword(network, passwordField.text)
    signal joinRequested(name: string, password: string)
    signal cancelRequested

    spacing: 12
    onOpenedChanged: {
        if (opened)
            focusInput();
        else
            passwordField.clear();
    }
    onBusyChanged: {
        if (busy)
            passwordField.clear();
        else
            focusInput();
    }
    Component.onCompleted: focusInput()

    function focusInput() {
        Qt.callLater(() => {
            if (root.opened && !root.busy)
                (root.hidden ? nameField : passwordField).forceActiveFocus();
        });
    }

    Icon {
        Layout.alignment: Qt.AlignHCenter
        implicitSize: 32
        name: root.network !== null ? Network.iconName(root.network) : "network-wireless-signal-excellent-symbolic"
        color: Theme.textSecondary
        pulsing: root.busy
    }

    Text {
        Layout.fillWidth: true
        visible: !root.hidden
        text: root.network?.name ?? ""
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 15
        font.bold: true
        color: Theme.textPrimary
        wrapMode: Text.Wrap
    }

    TextField {
        id: nameField
        visible: root.hidden
        enabled: !root.busy
        placeholderText: "Network name"
        onAccepted: passwordField.forceActiveFocus()
    }

    TextField {
        id: passwordField
        enabled: !root.busy
        placeholderText: "Password"
        password: true
        onAccepted: if (joinButton.enabled)
            joinButton.clicked()
    }

    Text {
        Layout.fillWidth: true
        visible: root.hidden
        leftPadding: nameField.leftPadding
        rightPadding: nameField.rightPadding
        text: "Leave the password empty for an open network."
        color: Theme.textSecondary
        font.pixelSize: 11
        wrapMode: Text.Wrap
    }

    Text {
        Layout.fillWidth: true
        visible: root.error !== ""
        leftPadding: nameField.leftPadding
        rightPadding: nameField.rightPadding
        text: root.error
        color: Theme.warning
        font.pixelSize: 12
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.fillWidth: false
        Layout.preferredWidth: 2 * Math.ceil(Math.max(cancelButton.implicitWidth, joinButton.implicitWidth)) + spacing
        uniformCellSizes: true

        Button {
            id: cancelButton
            Layout.fillWidth: true
            text: "Cancel"
            onClicked: root.cancelRequested()
        }

        Button {
            id: joinButton
            Layout.fillWidth: true
            variant: Button.Accent
            text: root.busy ? "Connecting…" : root.error ? "Try again" : "Join"
            enabled: !root.busy && root.validPassword && (!root.hidden || nameField.text.trim() !== "")
            onClicked: root.joinRequested(nameField.text.trim(), passwordField.text)
        }
    }
}
