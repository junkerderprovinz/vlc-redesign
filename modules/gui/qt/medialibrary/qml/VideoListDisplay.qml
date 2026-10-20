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
import QtQml.Models

import VLC.MediaLibrary

import VLC.Util
import VLC.Widgets as Widgets
import VLC.MainInterface
import VLC.Player
import VLC.Style

Widgets.ListGridView {
    id: listView

    // Properties

    property MLDragItem dragItem
    property MLContextMenu contextMenu

    // Signals

    signal itemDoubleClicked(var model)

    // Settings

    activeFocusOnTab: true

    // Children

    delegate: Widgets.ListGridItem {
        id: listItem

        // Properties

        required property var model
        required property int index

        // Groups and folders have no isVideo role, or have it set to false.
        readonly property bool isContainer: (model.isVideo !== true)

        readonly property real mediaProgress: Helpers.clamp(model.progress ?? 0, 0, 1)

        readonly property bool watched: !isContainer
                                        && (mediaProgress >= 0.85
                                            || ((model.playcount ?? 0) > 0 && !(mediaProgress > 0)))

        // Settings

        width: listView.cellWidth
        height: listView.cellHeight

        image: isContainer ? "" : (model.thumbnail || "")
        fallbackImage: VLCStyle.noArtVideoCover
        iconText: isContainer ? VLCIcons.folder : ""

        title: model.title || qsTr("Unknown title")

        progress: mediaProgress > 0 ? mediaProgress : (watched ? 1 : 0)
        dimmed: watched || isContainer

        current: !isContainer && Player.isStarted && !!model.mrl
                 && model.mrl.toString() === Player.url.toString()

        dragItem: listView.dragItem

        // Events

        onItemClicked: (modifier, select) => { listView.leftClickOnItem(modifier, index, select) }

        onItemDoubleClicked: listView.itemDoubleClicked(model)

        onContextMenuButtonClicked: (_, globalMousePos) => {
            listView.rightClickOnItem(index)

            listView.contextMenu.popup(listView.selectionModel.selectedIndexes, globalMousePos)
        }
    }
}
