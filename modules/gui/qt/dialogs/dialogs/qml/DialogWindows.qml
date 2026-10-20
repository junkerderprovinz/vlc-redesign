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

import VLC.Dialogs

// Dialog windows requested through DialogsProvider. They are created on
// first use and kept, so they outlive changes of the interface mode.
Item {
    id: root

    function _show(loader) {
        loader.active = true
        loader.item.open()
    }

    Loader {
        id: networkStream
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/NetworkStreamDialog.qml"
    }

    Loader {
        id: addSubtitles
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/AddSubtitlesDialog.qml"
    }

    Loader {
        id: keyboardShortcuts
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/KeyboardShortcutsDialog.qml"
    }

    Loader {
        id: newPlaylist
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/NewPlaylistDialog.qml"
    }

    Loader {
        id: addToPlaylist
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/AddToPlaylistDialog.qml"
    }

    Loader {
        id: about
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/AboutDialog.qml"
    }

    Connections {
        target: DialogsProvider

        function onShowNetworkStreamDialog() { root._show(networkStream) }
        function onShowAddSubtitlesDialog() { root._show(addSubtitles) }
        function onShowKeyboardShortcutsDialog() { root._show(keyboardShortcuts) }
        function onShowNewPlaylistDialog() { root._show(newPlaylist) }
        function onShowAddToPlaylistDialog(medias, type) {
            addToPlaylist.active = true
            addToPlaylist.item.medias = medias
            addToPlaylist.item.playlistType = type
            addToPlaylist.item.open()
        }
        function onShowAboutDialog() { root._show(about) }
    }
}
