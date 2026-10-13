pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.bar as Bar
import qs.config
import qs.services

Bar.Button {
    id: root

    function versionDiff(version: string, otherVersion: string, bold = false): string {
        const escape = text => text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
        const highlight = text => '<font color="' + Theme.critical + '">' + (bold ? "<b>" + escape(text) + "</b>" : escape(text)) + "</font>";
        if (version === "latest-commit")
            return highlight(version);
        if (otherVersion === "latest-commit")
            return escape(version);
        const tokenize = value => value.match(/g?[a-f\d]{7,64}(?=$|[._+~-])|\d+|[a-z]+|[^a-z\d]+/gi) || [];
        const parts = tokenize(version);
        const otherParts = tokenize(otherVersion);
        const matches = Array.from({
            length: parts.length + 1
        }, () => Array(otherParts.length + 1).fill(0));
        for (let i = parts.length - 1; i >= 0; i--) {
            for (let j = otherParts.length - 1; j >= 0; j--)
                matches[i][j] = parts[i] === otherParts[j] ? matches[i + 1][j + 1] + 1 : Math.max(matches[i + 1][j], matches[i][j + 1]);
        }
        let result = "";
        let i = 0;
        let j = 0;
        while (i < parts.length) {
            if (j < otherParts.length && parts[i] === otherParts[j]) {
                result += escape(parts[i++]);
                j++;
            } else if (j < otherParts.length && matches[i][j + 1] > matches[i + 1][j]) {
                j++;
            } else {
                result += highlight(parts[i++]);
            }
        }
        return result;
    }

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    visible: Updates.news.length > 0 || Updates.checking || Updates.installerOpen || Updates.error !== "" || Updates.count > 0
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            popup.closeOthers();
            Updates.refresh();
        } else if (mouse.button === Qt.MiddleButton) {
            popup.closeAll();
            Updates.install();
        } else {
            popup.toggle();
        }
    }

    content: RowLayout {
        spacing: 4

        Icon {
            id: refreshIcon
            name: "emblem-synchronizing-symbolic"
            NumberAnimation on backer.rotation {
                from: 0
                to: 360
                duration: 1300
                loops: Animation.Infinite
                running: Updates.checking
                onStopped: refreshIcon.backer.rotation = 0
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 6
                height: 6
                radius: 3
                visible: Updates.news.length > 0
                color: Theme.warning
                border.color: Theme.barBackground
                border.width: 1
            }
        }

        Text {
            color: Updates.error !== "" ? Theme.warning : Theme.textPrimary
            text: Updates.count
        }
    }

    Bar.Popup {
        id: popup
        anchorItem: root

        ColumnLayout {
            RowLayout {
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Updates"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                }
                RefreshControl {
                    updatedAt: Updates.updatedAt
                    refreshing: Updates.checking
                    onRefreshRequested: Updates.refresh()
                }
                Button {
                    id: updateButton
                    visible: Updates.count > 0
                    flat: true
                    text: "Install updates"
                    enabled: !Updates.checking && !Updates.installerOpen
                    onClicked: {
                        popup.closeAll();
                        Updates.install();
                    }

                    iconName: "system-software-install-symbolic"
                    icon.width: 14
                    icon.height: 14
                    icon.color: Theme.textSecondary
                    display: AbstractButton.IconOnly

                    Tooltip {
                        anchorItem: updateButton
                        text: updateButton.text
                    }
                }
            }

            ColumnLayout {
                visible: Updates.news.length > 0
                spacing: 8

                Text {
                    text: "Arch news"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textSecondary
                }
                Repeater {
                    model: Updates.news
                    delegate: RowLayout {
                        id: article
                        required property var modelData
                        spacing: 8

                        Text {
                            id: headline
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: article.modelData.title
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: Theme.textPrimary
                            font.underline: newsTooltip.hovered
                            TapHandler {
                                onTapped: {
                                    popup.closeAll();
                                    Qt.openUrlExternally(article.modelData.url);
                                }
                            }
                            Tooltip {
                                id: newsTooltip
                                anchorItem: headline
                                cursorShape: Qt.PointingHandCursor
                                text: article.modelData.url
                            }
                        }
                        Text {
                            id: newsDate
                            Layout.alignment: Qt.AlignTop
                            text: Qt.formatDateTime(article.modelData.date, "MMM d")
                            font.pixelSize: 11
                            color: Theme.textTertiary

                            Tooltip {
                                anchorItem: newsDate
                                text: Qt.formatDateTime(article.modelData.date, "yyyy-MM-dd hh:mm:ss")
                            }
                        }
                    }
                }
                Separator {
                    visible: Updates.count > 0
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: Updates.error !== ""
                text: Updates.error
                color: Theme.critical
                wrapMode: Text.Wrap
            }
            Text {
                visible: Updates.count === 0 && Updates.error === ""
                text: "No updates"
                color: Theme.textSecondary
            }

            ListView {
                id: packageList
                readonly property int oldVersionWidth: Math.min(100, Math.ceil(Updates.packages.reduce((width, pkg) => Math.max(width, versionMetrics.advanceWidth(pkg.oldVersion)), 0)))
                readonly property int newVersionWidth: Math.min(100, Math.ceil(Updates.packages.reduce((width, pkg) => Math.max(width, newVersionMetrics.advanceWidth(pkg.newVersion)), 0)))

                implicitWidth: 400
                implicitHeight: Math.min(contentHeight, 320)
                clip: true
                spacing: 4
                model: Updates.packages
                section.property: "source"
                section.criteria: ViewSection.FullString
                ScrollBar.vertical: ScrollBar {}

                FontMetrics {
                    id: versionMetrics
                }

                FontMetrics {
                    id: newVersionMetrics
                    font.bold: true
                }

                section.delegate: Text {
                    required property string section

                    width: packageList.width
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textSecondary
                    text: section + " · " + Updates.packages.filter(pkg => pkg.source === section).length
                }

                delegate: RowLayout {
                    id: packageRow
                    required property var modelData
                    readonly property string updateLevel: Updates.updateLevel(modelData.oldVersion, modelData.newVersion)
                    readonly property string url: Updates.link(modelData.name)

                    width: packageList.width
                    height: 24
                    spacing: 8
                    Text {
                        id: packageName
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.bold: packageRow.updateLevel !== "normal"
                        font.underline: packageTooltip.hovered && packageRow.url !== ""
                        color: packageRow.updateLevel === "major" ? Theme.critical : Theme.textPrimary
                        textFormat: Text.StyledText
                        text: packageRow.modelData.name + (Updates.importantPackages.includes(packageRow.modelData.name) ? ' <font color="' + Theme.textSecondary + '">★</font>' : "")

                        TapHandler {
                            enabled: packageRow.url !== ""
                            onTapped: {
                                popup.closeAll();
                                Updates.openDetails(packageRow.modelData.name);
                            }
                        }

                        Tooltip {
                            id: packageTooltip
                            anchorItem: packageName
                            atCursor: true
                            enabled: packageRow.url !== "" || packageName.truncated
                            cursorShape: packageRow.url ? Qt.PointingHandCursor : Qt.ArrowCursor
                            text: (packageName.truncated ? packageRow.modelData.name + "\n" : "") + packageRow.url
                        }
                    }
                    RowLayout {
                        id: versions
                        spacing: packageRow.spacing

                        Text {
                            id: oldVersion
                            Layout.preferredWidth: packageList.oldVersionWidth
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            textFormat: Text.StyledText
                            color: Theme.textTertiary
                            text: root.versionDiff(packageRow.modelData.oldVersion, packageRow.modelData.newVersion)
                        }
                        Text {
                            id: newVersion
                            Layout.preferredWidth: packageList.newVersionWidth
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            textFormat: Text.StyledText
                            color: Theme.textSecondary
                            text: root.versionDiff(packageRow.modelData.newVersion, packageRow.modelData.oldVersion, true)
                        }

                        Tooltip {
                            anchorItem: versions
                            enabled: oldVersion.truncated || newVersion.truncated
                            text: packageRow.modelData.oldVersion + " → " + packageRow.modelData.newVersion
                        }
                    }
                }
            }
        }
    }
}
