/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
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


import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Playlist
import VLC.Player
import VLC.Style
import VLC.Util
import VLC.Dialogs

// Floating panel of the player with the play queue, the bookmarks and the
// chapters of the current media.
Widgets.FloatingPanel {
    id: root

    enum Tab {
        Queue,
        Bookmarks,
        Chapters
    }

    property alias playlistView: playlistView

    currentTab: QueuePanel.Tab.Queue

    tabs: [
        { text: qsTr("Play Queue"), iconTxt: VLCIcons.queue },
        { text: qsTr("Bookmarks"), iconTxt: VLCIcons.bookmarks },
        { text: qsTr("Chapters"), iconTxt: VLCIcons.chapters }
    ]

    onTabClicked: (index) => root.currentTab = index

    StackLayout {
        anchors.fill: parent

        currentIndex: root.currentTab

        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: ColorContext.Window
        }

        PlaylistPane {
            id: playlistView

            useAcrylic: false
            focus: true

            wheelEnabled: true

            topPadding: 0
            bottomPadding: 0

            background: null
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
                Layout.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)
                Layout.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

                spacing: VLCStyle.margin_small

                T.Label {
                    Layout.fillWidth: true

                    text: qsTr("%1 Bookmark", "%1 Bookmarks", bookmarkList.count).arg(bookmarkList.count)
                    color: theme.tokens.fgA3
                    font.pixelSize: VLCStyle.fontSize_large
                    elide: Text.ElideRight
                }

                Widgets.IconToolButton {
                    font.pixelSize: VLCStyle.icon_normal

                    text: VLCIcons.edit
                    description: qsTr("Manage bookmarks")

                    onClicked: DialogsProvider.bookmarksDialog()
                }

                Widgets.IconToolButton {
                    font.pixelSize: VLCStyle.icon_normal

                    enabled: MainCtx.mediaLibraryAvailable && Player.isStarted
                    text: VLCIcons.add
                    description: qsTr("Add bookmark")

                    onClicked: bookmarkLoader.item?.add()
                }
            }

            Loader {
                id: bookmarkLoader

                active: MainCtx.mediaLibraryAvailable

                sourceComponent: MLBookmarkModel {
                    player: Player
                    ml: MediaLib
                }
            }

            ChoiceList {
                id: bookmarkList

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: bookmarkLoader.item

                emptyText: MainCtx.mediaLibraryAvailable ? qsTr("Add a bookmark to jump back to this moment later.")
                                                         : qsTr("Bookmarks need the media library.")

                delegate: MarkRow {
                    required property var model
                    required property int index

                    name: model.name
                    trailing: model.time

                    onClicked: bookmarkLoader.item.select(bookmarkLoader.item.index(index, 0))
                }
            }
        }

        ChoiceList {
            id: chapterList

            topMargin: VLCStyle.dp(20, VLCStyle.scale)

            model: Player.chapters

            emptyText: qsTr("This media has no chapters.")

            delegate: MarkRow {
                required property var model
                required property int index

                number: index + 1
                name: model.display
                trailing: model.time.formatHMS()
                current: model.checked

                onClicked: Player.chapters.selectChapter(index)
            }
        }
    }

    component ChoiceList : ListView {
        id: list

        property string emptyText

        clip: true
        spacing: VLCStyle.margin_small

        leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        bottomMargin: VLCStyle.dp(20, VLCStyle.scale)

        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        T.Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)

            visible: list.count === 0

            text: list.emptyText
            color: theme.tokens.fgA3
            font.pixelSize: VLCStyle.fontSize_large
            wrapMode: Text.WordWrap
        }
    }

    component MarkRow : T.ItemDelegate {
        id: row

        property string name
        property string trailing
        property int number: 0
        property bool current: false

        width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        horizontalPadding: VLCStyle.dp(4, VLCStyle.scale)

        hoverEnabled: true

        Accessible.name: name

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: (row.hovered || row.visualFocus) ? theme.tokens.hover : "transparent"
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            T.Label {
                Layout.preferredWidth: VLCStyle.dp(34, VLCStyle.scale)

                visible: row.number > 0

                text: row.number
                color: theme.accent
                font.pixelSize: VLCStyle.fontSize_large
                font.weight: Font.Medium
            }

            T.Label {
                Layout.fillWidth: true

                text: row.name
                color: row.current ? theme.accent : theme.tokens.fgA1
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }

            T.Label {
                text: row.trailing
                color: theme.tokens.fgA3
                font.pixelSize: VLCStyle.fontSize_large
            }
        }
    }
}
