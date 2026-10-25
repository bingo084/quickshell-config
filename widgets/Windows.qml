pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen

    spacing: 0

    Repeater {
        model: NiriService.workspaces

        RowLayout {
            id: workspace
            required property var model

            spacing: 0
            visible: workspace.model.isActive && workspace.model.output === root.screen?.name

            Repeater {
                model: workspace.visible ? NiriService.sortedWindows : 0

                MouseArea {
                    id: area
                    required property var model

                    implicitWidth: background.implicitWidth
                    implicitHeight: background.implicitHeight
                    Layout.fillWidth: true
                    Layout.maximumWidth: 200
                    visible: workspace.model.id === model.workspaceId
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const sameAnchor = popup.visible && popup.anchorItem === area;
                        popup.closeAll();
                        if (mouse.button === Qt.LeftButton)
                            NiriService.focusWindow(model.id);
                        else if (mouse.button === Qt.RightButton && !sameAnchor) {
                            popup.anchorItem = area;
                            popup.open();
                        } else if (mouse.button === Qt.MiddleButton)
                            NiriService.closeWindow(model.id);
                    }

                    Tooltip {
                        anchorItem: area
                        enabled: title.truncated && !area.pressed && !popup.visible
                        text: title.text
                    }

                    Shadow {
                        anchors.fill: background
                        radius: background.radius
                        blur: 6
                        offset.y: 1
                        color: Theme.selectedShadow
                        visible: area.model.isFocused
                    }

                    WrapperRectangle {
                        id: background
                        width: area.width
                        readonly property color overlayColor: area.pressed ? Theme.pressOverlay : area.containsMouse ? Theme.hoverOverlay : "transparent"

                        implicitHeight: 30
                        margin: 5
                        radius: 4
                        color: area.model.isFocused ? Qt.tint(Theme.selectedBackground, overlayColor) : overlayColor
                        border.width: area.model.isFocused ? 1 : 0
                        border.color: Theme.border

                        child: RowLayout {
                            Icon {
                                readonly property var iconByTitle: ({
                                        "飞书": "/usr/share/icons/hicolor/256x256/apps/bytedance-feishu.png"
                                    })
                                readonly property string fixedIconPath: iconByTitle[area.model.title] ?? area.model.iconPath

                                color: "transparent"
                                source: fixedIconPath ? "file://" + fixedIconPath : ""
                                visible: fixedIconPath !== ""
                            }
                            Text {
                                id: title
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: _format(area.model.title, area.model.appId)
                                color: Theme.textPrimary
                                font.weight: area.model.isFocused ? Font.Bold : Font.Normal

                                function _format(title: string, appId: string): string {
                                    if (appId === "google-chrome") {
                                        return title.replace(/ - Google Chrome$/, "");
                                    }
                                    return title;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentMargin: 6
        readonly property var targetItem: anchorItem

        ColumnLayout {
            spacing: 1
            MenuItem {
                iconName: "xapp-view-fit-width-symbolic"
                text: "Full Width"
                onTriggered: {
                    popup.close();
                    NiriService.maximizeColumn(popup.targetItem.model.id);
                }
            }
            MenuItem {
                iconName: "screenshot-window-symbolic"
                text: "Maximize"
                onTriggered: {
                    popup.close();
                    NiriService.maximizeWindowToEdges(popup.targetItem.model.id);
                }
            }
            MenuItem {
                iconName: "view-fullscreen-symbolic"
                text: "Fullscreen"
                onTriggered: {
                    popup.close();
                    NiriService.toggleFullscreen(popup.targetItem.model.id);
                }
            }
            MenuItem {
                iconName: "window-pop-out-symbolic"
                text: "Floating"
                checked: popup.targetItem?.model?.isFloating ?? false
                onTriggered: {
                    popup.close();
                    NiriService.toggleFloating(popup.targetItem.model.id);
                }
            }
            Separator {
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }
            MenuItem {
                iconName: "window-close-symbolic"
                text: "Close"
                onTriggered: {
                    popup.close();
                    NiriService.closeWindow(popup.targetItem.model.id);
                }
            }
        }
    }
}
