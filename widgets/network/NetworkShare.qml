pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    required property WifiNetwork network
    required property var profile
    property var result: null
    property string error
    readonly property var lifetime: ({
            active: true
        })

    spacing: 12
    Component.onCompleted: {
        const lifetime = root.lifetime;
        Promise.resolve().then(() => {
            if (lifetime.active)
                return NetworkService.queryShare(root.network, root.profile);
        }).then(result => {
            if (lifetime.active)
                root.result = result;
        }).catch(error => {
            if (lifetime.active)
                root.error = error.message;
        });
    }
    Component.onDestruction: lifetime.active = false

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        text: root.network?.name ?? ""
        font.pixelSize: 15
        font.bold: true
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Rectangle {
            implicitWidth: 208
            implicitHeight: 208
            radius: 8
            color: root.result ? "white" : Theme.controlBackground

            Image {
                id: code
                anchors.fill: parent
                anchors.margins: 4
                source: root.result?.image ?? ""
                smooth: false
                cache: false
                onStatusChanged: if (status === Image.Error)
                    root.error = "Could not display the QR code."
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 24
                visible: !root.result || root.error !== ""
                text: root.error || "Preparing…"
                font.pixelSize: 12
                color: root.error ? Theme.warning : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: code.status === Image.Ready
            text: "Scan to connect"
            font.pixelSize: 12
            color: Theme.textSecondary
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width
            visible: text !== ""
            text: root.result?.password ?? ""
            iconName: "workspacelistentryicon-key-symbolic"
            icon.width: 14
            icon.height: 14
            icon.color: Theme.textSecondary
            font.pixelSize: 13
            onClicked: Quickshell.clipboardText = text
            tooltip.text: "Copy password\n" + (root.result?.password ?? "")
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.result?.password === ""
            text: "No password required"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
    }
}
