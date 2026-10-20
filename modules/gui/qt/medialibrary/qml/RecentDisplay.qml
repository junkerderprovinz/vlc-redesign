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

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Player
import VLC.Util
import VLC.Style

// The media played last, newest first.
Widgets.PageExt {
    id: root

    title: qsTr("Recent")

    hasGridListMode: false
    isSearchable: false

    count: recentModel.count

    function setCurrentItemFocus(reason) {
        recentView.setCurrentItemFocus(reason)
    }

    function positionContentAtBeginning() {
        recentView.positionViewAtBeginningAnimated()
    }

    FocusScope {
        anchors.fill: parent

        focus: true

        Widgets.ListGridView {
            id: recentView

            anchors.fill: parent

            visible: recentModel.count > 0
            focus: recentModel.count > 0

            model: recentModel

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            delegate: Widgets.ListGridItem {
                required property var model
                required property int index

                width: recentView.cellWidth
                height: recentView.cellHeight

                image: model.small_cover ?? ""
                fallbackImage: model.isVideo ? VLCStyle.noArtVideoCover : VLCStyle.noArtAlbumCover

                title: model.title || qsTr("Unknown title")

                progress: Helpers.clamp(model.progress ?? 0, 0, 1)

                current: Player.isStarted && !!model.mrl
                         && model.mrl.toString() === Player.url.toString()

                onItemClicked: (modifier, select) => { recentView.leftClickOnItem(modifier, index, select) }

                onItemDoubleClicked: MediaLib.addAndPlay(model.id)

                onPlayClicked: MediaLib.addAndPlay(model.id)

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    recentView.rightClickOnItem(index)
                    contextMenu.popup(recentView.selectionModel.selectedIndexes, globalMousePos)
                }
            }

            onActionAtIndex: recentModel.addAndPlay(selectionModel.selectedIndexes)

            Navigation.parentItem: root
            Navigation.upItem: root.header
        }

        Widgets.EmptyLabelButton {
            anchors.centerIn: parent

            visible: !recentModel.loading && (recentModel.count <= 0)
            focus: visible

            text: qsTr("Nothing played yet")

            Navigation.parentItem: root
        }
    }

    MLRecentMediaModel {
        id: recentModel

        ml: MediaLib
    }

    MLContextMenu {
        id: contextMenu

        model: recentModel
    }
}
