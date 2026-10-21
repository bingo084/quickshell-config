pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarButton {
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
    visible: UpdateService.news.length > 0 || UpdateService.checking || UpdateService.installerOpen || UpdateService.error !== "" || UpdateService.count > 0
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            popup.closeOthers();
            UpdateService.refresh();
        } else if (mouse.button === Qt.MiddleButton) {
            popup.closeAll();
            UpdateService.install();
        } else {
            popup.toggle();
        }
    }

    content: RowLayout {
        spacing: 4

        Icon {
            name: "emblem-synchronizing-symbolic"
            color: UpdateService.error !== "" ? Theme.warning : Theme.textPrimary
            spinning: UpdateService.checking
            showBadge: UpdateService.news.length > 0
        }

        Text {
            color: UpdateService.count >= 100 ? Theme.critical : UpdateService.count >= 50 ? Theme.warning : Theme.textPrimary
            text: UpdateService.count
        }
    }

    Popup {
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
                    updatedAt: UpdateService.updatedAt
                    refreshing: UpdateService.checking
                    onRefreshRequested: UpdateService.refresh()
                }
                Button {
                    visible: UpdateService.count > 0
                    text: "Install updates"
                    enabled: !UpdateService.checking && !UpdateService.installerOpen
                    onClicked: {
                        popup.closeAll();
                        UpdateService.install();
                    }

                    iconName: "system-software-install-symbolic"
                    icon.width: 14
                    icon.height: 14
                    icon.color: Theme.textSecondary
                    display: AbstractButton.IconOnly

                    tooltip.text: text
                }
            }

            ColumnLayout {
                visible: UpdateService.news.length > 0
                spacing: 8

                Text {
                    text: "Arch news"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textSecondary
                }
                Repeater {
                    model: UpdateService.news
                    delegate: RowLayout {
                        id: article
                        required property var modelData
                        spacing: 8

                        Link {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: article.modelData.title
                            url: article.modelData.url
                            wrapMode: Text.Wrap
                        }
                        Text {
                            id: newsDate
                            Layout.alignment: Qt.AlignTop
                            text: Qt.formatDateTime(article.modelData.date, ClockService.dateFormat)
                            font.pixelSize: 11
                            color: Theme.textTertiary

                            Tooltip {
                                anchorItem: newsDate
                                text: Qt.formatDateTime(article.modelData.date, ClockService.fullDateTimeFormat)
                            }
                        }
                    }
                }
                Separator {
                    visible: UpdateService.count > 0
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: UpdateService.error !== ""
                text: UpdateService.error
                color: Theme.warning
                wrapMode: Text.Wrap
            }
            Text {
                visible: UpdateService.count === 0 && UpdateService.error === ""
                text: "No updates"
                color: Theme.textSecondary
            }

            ListView {
                id: packageList
                readonly property int oldVersionWidth: Math.min(100, Math.ceil(UpdateService.packages.reduce((width, pkg) => Math.max(width, versionMetrics.advanceWidth(pkg.oldVersion)), 0)))
                readonly property int newVersionWidth: Math.min(100, Math.ceil(UpdateService.packages.reduce((width, pkg) => Math.max(width, newVersionMetrics.advanceWidth(pkg.newVersion)), 0)))

                implicitWidth: 400
                implicitHeight: Math.min(contentHeight, 320)
                clip: true
                spacing: 4
                model: UpdateService.packages
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
                    text: section + " · " + UpdateService.packages.filter(pkg => pkg.source === section).length
                }

                delegate: RowLayout {
                    id: packageRow
                    required property var modelData
                    readonly property string updateLevel: UpdateService.updateLevel(modelData.oldVersion, modelData.newVersion)

                    width: packageList.width
                    height: 24
                    spacing: 8
                    Link {
                        id: packageName
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rightPadding: marker.visible ? marker.width + packageRow.spacing : 0
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.bold: packageRow.updateLevel !== "normal"
                        color: packageRow.updateLevel === "major" ? Theme.critical : Theme.textPrimary
                        text: packageRow.modelData.name
                        url: UpdateService.link(packageRow.modelData.name)
                        tooltip.atCursor: true

                        Text {
                            id: marker
                            x: Math.min(Math.ceil(packageName.contentWidth) + packageRow.spacing, packageName.width - width)
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.ceil(implicitWidth)
                            visible: UpdateService.importantPackages.includes(packageRow.modelData.name)
                            text: "★"
                            color: Theme.textSecondary
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
