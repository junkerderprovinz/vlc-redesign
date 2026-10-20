
/*****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
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
import QtQml

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Dialogs

import VLC.Util

// @brief - a generic ML context menu
NativeMenu {
    id: root

    // Properties

    required property MLBaseModel model

    property string idDataRole: "id"
    property string albumIdDataRole: "album_id"

    property bool showPlayAsAudioAction: false

    // This is only applicable when the model is `MLAudioModel`:
    property bool showPlayAsAlbumAction: implicitShowPlayAsAlbumAction
    property bool implicitShowPlayAsAlbumAction: !showPlayAsAudioAction

    // Signals

    signal showMediaInformation(int index)


    // required by TableViewExt
    property var tableView_popup: function (index/* reserved for future */, selectedIndexes, globalPos) {
        return popup(selectedIndexes, globalPos)
    }

    // Settings

    actions: [{
            "text": qsTr("Play"),
            "icon": ":/icons/ui/playback-duo.svg",
            "action": addAndPlay
        }, {
            "text": qsTr("Play as Audio"),
            "icon": ":/icons/ui/audio-duo.svg",
            "action": playAsAudio,
            "visible": root.showPlayAsAudioAction
        }, {
            "text": qsTr("Play as Album"),
            "icon": ":/icons/ui/album.svg",
            "action": playAsAlbum,
            "visible": root.showPlayAsAlbumAction &&
                       (root.model instanceof MLAudioModel)
        }, {
            "text": qsTr("Mark as Watched"),
            "icon": ":/icons/ui/check-selected-duo.svg",
            "action": markSeen,
            "visible": _showSeen
        }, {
            "text": qsTr("Mark as Unwatched"),
            "icon": ":/icons/ui/check-selected-duo.svg",
            "action": markUnseen,
            "visible": _showUnseen
        }, {
            "text": qsTr("Favorite"),
            "icon": ":/icons/ui/favorite-duo.svg",
            "action": addFavorite,
            "visible": _showAddFavorite
        }, {
            "text": qsTr("Remove from Favorites"),
            "icon": ":/icons/ui/favorite-active.svg",
            "action": removeFavorite,
            "visible": _showRemoveFavorite
        }, {
            "text": qsTr("Stream"),
            "icon": ":/icons/ui/streaming-duo.svg",
            "action": stream,
            "visible": _hasMrl
        }, {
            "text": qsTr("Convert"),
            "icon": ":/icons/ui/swap-duo.svg",
            "action": convert,
            "visible": _hasMrl
        }, {
            "text": qsTr("Add to Queue"),
            "icon": ":/icons/ui/queue-duo.svg",
            "action": enqueue
        }, {
            "text": qsTr("Add Album to Queue"),
            "icon": ":/icons/ui/queue-duo.svg",
            "action": enqueueAsAlbum,
            "visible": root.showPlayAsAlbumAction &&
                       (root.model instanceof MLAudioModel)
        }, {
            "text": qsTr("Add to Playlist"),
            "icon": ":/icons/ui/playlist-duo.svg",
            "action": addToAPlaylist
        }, {
            "text": (root.showPlayAsAudioAction ? qsTr("Add to Video Playlist") : qsTr("Add to Audio Playlist")),
            "icon": (root.showPlayAsAudioAction ? ":/icons/ui/video-duo.svg" : ":/icons/ui/audio-duo.svg"),
            "action": (root.showPlayAsAudioAction ? root.addToVideoOnlyPlaylist : root.addToAudioOnlyPlaylist)
        }, {
            "text": qsTr("Show in File Explorer"),
            "icon": ":/icons/ui/folder-duo.svg",
            "action": openContainingFolder,
            "visible": _openContainingFolder
        }, {
            "text": qsTr("Info"),
            "icon": ":/icons/ui/window-duo.svg",
            "action": _signalShowInformation,
            "visible": showInformationAvailable
        }, {
            "text": qsTr("Properties && Metadata"),
            "icon": ":/icons/ui/info-duo.svg",
            "action": function(dataList, options, indexes) {
                DialogsProvider.mediaInfoDialog(dataList[0][idDataRole])
            },
            "visible": function(dataList, options, indexes) {
                return (dataList.length === 1)
                        && !(dataList[0][idDataRole].hasParent())
            }
        }, {
            "text": qsTr("Delete"),
            "icon": ":/icons/ui/remove.svg",
            "action": deleteStream,
            "visible": _deleteStream
        }, {
            "text": qsTr("Delete File From System"),
            "icon": ":/icons/ui/remove.svg",
            "action": deleteFileFromSource,
            "visible": _deleteFileFromSource
        }
    ]

    // Events

    onRequestData: (requestID, indexes) => {
        model.getData(indexes, function (data) {
            setData(requestID, data)
        })
    }

    // Functions

    function addAndPlay(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList), _playerOptions(options))
    }

    function playAsAudio(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList), _playerOptions(options, ":no-video"))
    }

    function playAsAlbum(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList, root.albumIdDataRole), _playerOptions(options))
    }

    function enqueue(dataList, options, indexes) {
        model.ml.addToPlaylist(_mlIDList(dataList), _playerOptions(options))
    }

    function enqueueAsAlbum(dataList, options, indexes) {
        model.ml.addToPlaylist(_mlIDList(dataList, root.albumIdDataRole), _playerOptions(options))
    }

    function addToAudioOnlyPlaylist(dataList, options, indexes) {
        addToAPlaylist(dataList, options, indexes, MLPlaylistListModel.PLAYLIST_TYPE_AUDIO_ONLY)
    }

    function addToVideoOnlyPlaylist(dataList, options, indexes) {
        addToAPlaylist(dataList, options, indexes, MLPlaylistListModel.PLAYLIST_TYPE_VIDEO_ONLY)
    }

    function addToAPlaylist(dataList, options, indexes, type) {
        if (type === undefined)
            type = MLPlaylistListModel.PLAYLIST_TYPE_ALL

        DialogsProvider.playlistsDialog(_mlIDList(dataList), type)
    }

    function addFavorite(dataList, options, indexes) {
        model.setMediaIsFavorite(indexes[0], true)
    }

    function removeFavorite(dataList, options, indexes) {
        model.setMediaIsFavorite(indexes[0], false)
    }

    function markSeen(dataList, options, indexes) {
        model.setItemPlayed(indexes[0], true)
    }

    function markUnseen(dataList, options, indexes) {
        model.setItemPlayed(indexes[0], false)
    }

    function stream(dataList, options, indexes) {
        DialogsProvider.streamingDialog(_mrlList(dataList), true)
    }

    function convert(dataList, options, indexes) {
        DialogsProvider.streamingDialog(_mrlList(dataList), false)
    }

    function openContainingFolder(dataList, options, indexes) {
        const parentDir = model.getParentURL(indexes[0]);

        Qt.openUrlExternally(parentDir)
    }

    function deleteStream(dataList, options, indexes) {
        model.deleteStream(dataList[0][idDataRole])
    }

    function deleteFileFromSource(dataList, options, indexes) {
        let confirm = DialogsProvider.questionDialog(qsTr("Are you sure you want to delete this file?"));
        
        if (confirm) {
            model.deleteFileFromSource(indexes[0]);
            console.log("File Deleted !!");
        }
    }

    function showInformationAvailable(dataList, options, indexes) {
        return indexes.length === 1
                && Helpers.isInteger(options?.["information"] ?? null)
    }

    // Private

    function _checkRole(dataList, role, expected) {
        if (dataList.length !== 1)
            return false

        if (!(role in dataList[0]))
            return false

        return (dataList[0][role] === expected)
    }

    function _showAddFavorite(dataList, options, indexes) {
        return _checkRole(dataList, "isFavorite", false)
    }

    function _showRemoveFavorite(dataList, options, indexes) {
        return _checkRole(dataList, "isFavorite", true)
    }

    function _showSeen(dataList, options, indexes) {
        return _checkRole(dataList, "isNew", true)
    }

    function _showUnseen(dataList, options, indexes) {
        return _checkRole(dataList, "isNew", false)
    }

    function _openContainingFolder(dataList, options, indexes) {
        return _checkRole(dataList, "isLocal", true)
    }

    function _hasMrl(dataList, options, indexes) {
        return dataList.length > 0 && dataList.every((data) => !!data.mrl)
    }

    function _mrlList(dataList) {
        return dataList.map((data) => data.mrl.toString())
    }

    function _deleteStream(dataList,options, indexes) {
        return _checkRole(dataList, "isDeletable", true)
    }

    function _deleteFileFromSource(dataList, options, indexes) {
        return  _checkRole(dataList, "isDeletableFile", true)
    }

    function _signalShowInformation(dataList, options) {
        const index = options?.["information"] ?? null
        console.assert(Helpers.isInteger(index))
        showMediaInformation(index)
    }

    function _playerOptions(options, extraOptions) {
        const playerOpts = options?.["player-options"] ?? []
        return playerOpts.concat(extraOptions)
    }

    function _mlIDList(dataList, role = root.idDataRole) {
        const idList = []
        for (let i in dataList) {
            console.assert(dataList[i][role] !== undefined)
            idList.push(dataList[i][role])
        }

        return idList
    }
}
