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
import QtQuick.Layouts
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.Player
import VLC.PlayerControls
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util

// Title bar of the player, laid out like the one of the main window so that
// switching between the library and the player keeps it in place.
FocusScope {
    id: root

    // Properties

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    readonly property int reservedHeight: implicitHeight

    property int topMargin: 0
    property int sideMargin: 0

    property string title

    property bool showCSD: false
    // also true while the pointer is over a window button that Windows
    // treats as non-client area, where no hover reaches the scene
    readonly property bool csdButtonHovered: csdDecorations.item?.buttonHovered ?? false
    property bool showToolbar: false
    property bool pinControls: false

    property bool overVideo: false

    property bool playlistVisible: false

    // the sidebar toggle shows the library beside the video, the folder chip
    // goes back to the library
    property bool showSidebarToggle: true
    property alias sidebarVisible: sidebarToggle.checked

    property bool showFolder: folderName !== ""
    property string folderName: _location

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    // Name of the folder holding the current media, or its host for a stream.
    readonly property string _location: {
        const url = Player.url
        if (!url || url.toString() === "")
            return ""

        const text = url.toString()
        if (!text.startsWith("file://")) {
            const host = text.replace(/^[a-z]+:\/\//i, "").split("/")[0]
            return host
        }

        const parts = text.split("/")
        if (parts.length < 2)
            return ""
        try {
            return decodeURIComponent(parts[parts.length - 2])
        } catch (e) {
            return parts[parts.length - 2]
        }
    }

    // Signals

    signal togglePlaylistVisibility()
    signal requestLockUnlockAutoHide(bool lock)
    signal backRequested()
    signal toggleSidebar()
    signal folderClicked()

    ///incomming signal to request all menu and popup to close
    signal forceUnlock()

    // Settings

    implicitHeight: topMargin + (showToolbar ? Math.max(menubar.implicitHeight, VLCStyle.globalToolbar_height)
                                             : VLCStyle.globalToolbar_height)

    Accessible.role: Accessible.ToolBar
    Accessible.name: qsTr("Player topbar")
    AccessibleCompat.id: "playerTopBar"

    onCsdButtonHoveredChanged: requestLockUnlockAutoHide(csdButtonHovered)

    // Children

    Rectangle {
        anchors.fill: parent

        color: root.overVideo ? theme.tokens.bgA3Glass : theme.bg.primary
    }

    //drag and dbl click the titlebar in CSD mode
    Loader {
        id: tapNDrag

        anchors.fill: parent
        active: root.showCSD
        source: "qrc:///qt/qml/VLC/Widgets/CSDTitlebarTapNDrapHandler.qml"

        Connections {
            target: tapNDrag.item
            enabled: tapNDrag.status === Loader.Ready
            function onCsdMenuVisibleChanged() {
                root.requestLockUnlockAutoHide(tapNDrag.item.csdMenuVisible)
            }
        }
    }

    component BarButton : Widgets.IconToolButton {
        implicitWidth: VLCStyle.dp(28, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

        font.pixelSize: VLCStyle.icon_normal
        radius: VLCStyle.dp(6, VLCStyle.scale)

        onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
    }

    RowLayout {
        id: leftGroup

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        anchors.leftMargin: root.sideMargin + VLCStyle.dp(6, VLCStyle.scale)

        height: VLCStyle.globalToolbar_height

        spacing: VLCStyle.dp(7, VLCStyle.scale)

        Widgets.BannerCone {
            Layout.leftMargin: VLCStyle.dp(7, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(7, VLCStyle.scale)
            Layout.alignment: Qt.AlignVCenter

            color: theme.accent
        }

        Menus.Menubar {
            id: menubar

            Layout.alignment: Qt.AlignVCenter

            visible: root.showToolbar
            enabled: root.showToolbar

            onHoveredChanged: menu => root.requestLockUnlockAutoHide(hovered)
            onMenuOpenedChanged: menu => root.requestLockUnlockAutoHide(menuOpened)
        }

        RowLayout {
            spacing: 0

            Layout.alignment: Qt.AlignVCenter

            BarButton {
                id: menuSelector

                visible: !root.showToolbar
                enabled: visible
                focus: visible

                text: VLCIcons.more
                description: qsTr("Menu")

                AccessibleCompat.id: "topBarMenuButton"

                checked: contextMenu.shown

                Navigation.parentItem: root
                Navigation.rightItem: sidebarToggle

                onClicked: contextMenu.popup(this.mapToGlobal(0, height))

                Menus.QmlGlobalMenu {
                    id: contextMenu

                    ctx: MainCtx

                    onAboutToShow: root.requestLockUnlockAutoHide(true)
                    onAboutToHide: root.requestLockUnlockAutoHide(false)
                }

                Connections {
                    target: root

                    function onForceUnlock() {
                        contextMenu.close()
                    }
                }
            }

            BarButton {
                id: sidebarToggle

                Layout.leftMargin: VLCStyle.dp(10, VLCStyle.scale)

                visible: root.showSidebarToggle

                text: VLCIcons.sidebar_left
                description: qsTr("Library Panel")

                AccessibleCompat.id: "sidebarToggleButton"

                focus: !menuSelector.visible

                Navigation.parentItem: root
                Navigation.leftItem: menuSelector.visible ? menuSelector : null
                Navigation.rightItem: locationButton

                onClicked: root.toggleSidebar()
            }

            Item {
                Layout.preferredWidth: VLCStyle.icon_normal
                Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)

                visible: locationButton.visible

                Rectangle {
                    anchors.centerIn: parent

                    width: VLCStyle.border
                    height: VLCStyle.dp(16, VLCStyle.scale)

                    color: theme.separator
                }
            }

            T.AbstractButton {
                id: locationButton

                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: root.width / 2 - leftGroup.x - x - centerTitleText.implicitWidth / 2 - VLCStyle.margin_normal

                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

                visible: root.showFolder

                rightPadding: VLCStyle.dp(4, VLCStyle.scale)

                hoverEnabled: true

                text: root.folderName

                Accessible.name: qsTr("Show in library")

                T.ToolTip.visible: hovered
                T.ToolTip.delay: VLCStyle.delayToolTipAppear
                T.ToolTip.text: Player.url.toString()

                Navigation.parentItem: root
                Navigation.leftItem: sidebarToggle

                onClicked: root.folderClicked()
                onHoveredChanged: root.requestLockUnlockAutoHide(hovered)

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: (locationButton.hovered || locationButton.visualFocus)
                           ? theme.tokens.hover : "transparent"
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.dp(4, VLCStyle.scale)

                    Widgets.IconLabel {
                        Layout.preferredWidth: VLCStyle.dp(28, VLCStyle.scale)

                        text: VLCIcons.folder
                        color: theme.tokens.fgA2
                        font.pixelSize: VLCStyle.icon_normal
                        horizontalAlignment: Text.AlignHCenter
                    }

                    T.Label {
                        Layout.fillWidth: true

                        text: locationButton.text
                        color: theme.tokens.fgA2
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    T.Label {
        id: centerTitleText

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topMargin

        height: VLCStyle.globalToolbar_height
        width: Math.min(implicitWidth, root.width - 2 * Math.max(leftGroup.x + leftGroup.width,
                                                                 root.width - csdDecorations.x) - 2 * VLCStyle.margin_normal)

        visible: !root.showToolbar

        text: root.title !== "" ? root.title : qsTr("VLC Media Player")
        color: theme.tokens.fgA2
        font.pixelSize: VLCStyle.fontSize_large
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    Loader {
        id: csdDecorations

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.topMargin + (VLCStyle.globalToolbar_height - height) / 2
        anchors.rightMargin: root.sideMargin + VLCStyle.dp(6, VLCStyle.scale)

        focus: false
        height: VLCStyle.icon_normal
        active: root.showCSD
        enabled: root.showCSD
        visible: root.showCSD
        source:  VLCStyle.palette.hasCSDImage
            ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
            : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
    }
}
