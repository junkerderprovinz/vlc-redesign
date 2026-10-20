/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

import QtQuick
import QtQuick.Templates as T
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util

T.ToolBar {
    id: root

    Accessible.name: qsTr("Title bar")
    AccessibleCompat.id: "localTopbar"

    property bool useAcrylic: true

    // The sidebar toggle and the folder chip only make sense next to the player,
    // the full library always shows its navigation.
    property bool showSidebarToggle: false
    property alias sidebarVisible: sidebarToggle.checked

    property bool showFolder: false
    property string folderName: MainCtx.hasEmbededVideo ? qsTr("Videos") : qsTr("Music")

    property string title: (Player.isStarted && Player.title) ? Player.title
                                                             : qsTr("VLC Media Player")

    property bool _showCSD: MainCtx.clientSideDecoration
        && !(MainCtx.intfMainWindow.visibility === Window.FullScreen)
        && !MainCtx.hasToolbarMenu

    signal toggleSidebar()
    signal folderClicked()

    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)

    leftPadding: VLCStyle.dp(6, VLCStyle.scale)
    rightPadding: VLCStyle.dp(6, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background: Widgets.AcrylicBackground {
        enabled: root.useAcrylic
        tintColor: theme.bg.primary
    }

    contentItem: Item {
        implicitHeight: VLCStyle.globalToolbar_height
        implicitWidth: startRow.implicitWidth + endRow.implicitWidth

        Loader {
            z: -1

            anchors.fill: parent
            active: root._showCSD
            sourceComponent: Widgets.CSDTitlebarTapNDrapHandler {
            }
        }

        Row {
            id: startRow

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            spacing: VLCStyle.dp(7, VLCStyle.scale)

            Navigation.parentItem: root
            Navigation.rightItem: endRow

            Item {
                width: VLCStyle.dp(38, VLCStyle.scale)
                height: VLCStyle.dp(28, VLCStyle.scale)

                Widgets.BannerCone {
                    anchors.centerIn: parent

                    sourceSize.width: VLCStyle.icon_normal
                    sourceSize.height: VLCStyle.icon_normal
                    color: theme.accent
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter

                spacing: VLCStyle.dp(10, VLCStyle.scale)

                TitleBarButton {
                    id: menuButton

                    focus: true

                    text: VLCIcons.more
                    description: qsTr("Menu")
                    checked: contextMenu.shown

                    AccessibleCompat.id: "menuButton"

                    Navigation.parentItem: startRow
                    Navigation.rightItem: sidebarToggle

                    onClicked: contextMenu.popup(this.mapToGlobal(0, height))

                    Menus.QmlGlobalMenu {
                        id: contextMenu
                        ctx: MainCtx
                    }
                }

                TitleBarButton {
                    id: sidebarToggle

                    visible: root.showSidebarToggle

                    text: VLCIcons.panel_left
                    description: qsTr("Toggle sidebar")

                    AccessibleCompat.id: "sidebarToggleButton"

                    Navigation.parentItem: startRow
                    Navigation.leftItem: menuButton
                    Navigation.rightItem: folderChip

                    onClicked: root.toggleSidebar()
                }
            }

            Item {
                visible: root.showFolder

                width: VLCStyle.icon_normal
                height: VLCStyle.dp(28, VLCStyle.scale)

                Rectangle {
                    anchors.centerIn: parent

                    width: VLCStyle.border
                    height: VLCStyle.dp(16, VLCStyle.scale)

                    color: theme.separator
                }
            }

            T.AbstractButton {
                id: folderChip

                visible: root.showFolder

                anchors.verticalCenter: parent.verticalCenter

                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

                rightPadding: VLCStyle.margin_xxsmall

                text: root.folderName

                Accessible.name: qsTr("Show in library")
                Accessible.onPressAction: folderChip.clicked()

                Navigation.parentItem: startRow
                Navigation.leftItem: sidebarToggle

                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

                onClicked: root.folderClicked()

                ColorContext {
                    id: chipTheme
                    colorSet: ColorContext.ToolButton

                    focused: folderChip.visualFocus
                    hovered: folderChip.hovered
                    pressed: folderChip.down
                }

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: folderChip.hovered ? chipTheme.bg.secondary : "transparent"
                    border.color: folderChip.visualFocus ? chipTheme.visualFocus : "transparent"
                }

                contentItem: Row {
                    spacing: VLCStyle.margin_xxsmall

                    Widgets.IconLabel {
                        width: VLCStyle.dp(28, VLCStyle.scale)
                        height: VLCStyle.dp(28, VLCStyle.scale)

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: VLCIcons.folder
                        color: chipTheme.fg.primary
                        font.pixelSize: VLCStyle.icon_normal
                    }

                    T.Label {
                        anchors.verticalCenter: parent.verticalCenter

                        width: Math.min(implicitWidth, VLCStyle.dp(160, VLCStyle.scale))

                        text: folderChip.text
                        elide: Text.ElideRight
                        color: chipTheme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_large
                    }
                }
            }
        }

        T.Label {
            anchors.centerIn: parent

            width: Math.min(implicitWidth,
                            parent.width - 2 * Math.max(startRow.width, endRow.width) - VLCStyle.margin_large)

            text: root.title
            elide: Text.ElideRight
            color: theme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large

            Accessible.ignored: true
        }

        Row {
            id: endRow

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Navigation.parentItem: root
            Navigation.leftItem: startRow

            Loader {
                height: parent.height

                active: root._showCSD
                source: VLCStyle.palette.hasCSDImage
                          ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
                          : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
            }
        }
    }

    component TitleBarButton: Widgets.IconToolButton {
        width: VLCStyle.dp(28, VLCStyle.scale)
        height: VLCStyle.dp(28, VLCStyle.scale)

        font.pixelSize: VLCStyle.icon_normal
    }
}
