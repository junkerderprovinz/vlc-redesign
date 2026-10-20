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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

// Only loaded when the media library is available, as VLC.MediaLibrary is
// registered only then.
FramelessDialog {
    id: root

    property var medias: []
    property int playlistType: MLPlaylistListModel.PLAYLIST_TYPE_ALL

    title: qsTr("Add to Playlist")

    designWidth: VLCStyle.dp(713, VLCStyle.scale)
    designHeight: VLCStyle.dp(589, VLCStyle.scale)

    acceptEnabled: medias.length > 0 && (list.currentIndex >= 0 || titleField.text.trim().length > 0)

    onVisibleChanged: {
        if (!visible)
            return
        list.currentIndex = -1
        titleField.text = ""
        titleField.forceActiveFocus()
    }

    onAccepted: {
        const name = titleField.text.trim()
        if (name.length > 0)
            playlists.create(name, medias)
        else
            playlists.append(playlists.getItemId(list.currentIndex), medias)
    }

    MLPlaylistListModel {
        id: playlists

        ml: MediaLib
        playlistType: root.playlistType
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.topMargin: VLCStyle.dp(22, VLCStyle.scale)
        anchors.bottomMargin: VLCStyle.dp(22, VLCStyle.scale)

        spacing: VLCStyle.dp(20, VLCStyle.scale)

        DialogHeading {
            Layout.fillWidth: true

            title: qsTr("Existing Playlist")
            description: qsTr("The selected media will be added to the end of the playlist.")
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            model: playlists
            currentIndex: -1
            spacing: VLCStyle.dp(4, VLCStyle.scale)
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            activeFocusOnTab: true

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            Accessible.role: Accessible.List
            Accessible.name: qsTr("Playlists")

            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    titleField.text = ""
            }

            delegate: T.ItemDelegate {
                id: row

                required property int index
                required property string name
                required property int count

                readonly property bool selected: ListView.isCurrentItem

                width: ListView.view.width
                height: VLCStyle.dp(36, VLCStyle.scale)

                leftPadding: VLCStyle.dp(8, VLCStyle.scale)
                rightPadding: VLCStyle.dp(8, VLCStyle.scale)

                Accessible.name: name

                onClicked: list.currentIndex = index

                onDoubleClicked: root.accept()

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: (row.selected || row.hovered) ? VLCStyle.palette.bgB2 : "transparent"
                    border.width: row.visualFocus ? VLCStyle.focus_border : 0
                    border.color: VLCStyle.palette.accentDim
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.dp(14, VLCStyle.scale)

                    Widgets.IconLabel {
                        text: VLCIcons.playlist
                        color: VLCStyle.palette.fgA2
                        font.pixelSize: VLCStyle.icon_normal
                    }

                    Widgets.LabelExt {
                        Layout.fillWidth: true

                        text: row.name
                        elide: Text.ElideRight
                        color: VLCStyle.palette.fgA1
                        font.pixelSize: VLCStyle.fontSize_normal
                        textFormat: Text.PlainText
                    }

                    Widgets.LabelExt {
                        text: row.count
                        color: VLCStyle.palette.fgA3
                        font.pixelSize: VLCStyle.fontSize_normal
                        textFormat: Text.PlainText
                    }

                    Widgets.IconLabel {
                        Layout.preferredWidth: VLCStyle.icon_normal

                        text: VLCIcons.check
                        color: VLCStyle.palette.accent
                        font.pixelSize: VLCStyle.icon_normal
                        opacity: row.selected ? 1 : 0
                    }
                }
            }

            Widgets.LabelExt {
                x: VLCStyle.dp(8, VLCStyle.scale)

                visible: list.count === 0
                text: qsTr("No playlists yet.")
                color: VLCStyle.palette.fgA3
                font.pixelSize: VLCStyle.fontSize_normal
                textFormat: Text.PlainText
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border

            color: VLCStyle.palette.dividerDim
        }

        DialogHeading {
            Layout.fillWidth: true

            title: qsTr("New Playlist")
            description: qsTr("Or create a playlist with this title.")
        }

        Widgets.TextFieldExt {
            id: titleField

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(37, VLCStyle.scale)

            leftPadding: VLCStyle.dp(14, VLCStyle.scale)
            rightPadding: VLCStyle.dp(18, VLCStyle.scale)

            placeholderText: qsTr("e.g., Favorite Videos")
            font.pixelSize: VLCStyle.fontSize_normal

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: VLCStyle.palette.bgB2
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: titleField.activeFocus ? VLCStyle.palette.accentDim : VLCStyle.palette.bgA4
            }

            Accessible.name: qsTr("New playlist title")

            onTextEdited: list.currentIndex = -1
            onAccepted: root.accept()
        }
    }
}
