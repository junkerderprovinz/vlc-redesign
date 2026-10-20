/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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

import VLC.MediaLibrary

import VLC.Util
import VLC.Widgets as Widgets
import VLC.MainInterface
import VLC.Style

MainViewLoader {
    id: root

    // Properties

    readonly property int currentIndex: currentItem?.currentIndex ?? - 1

    property Component header: null

    readonly property int contentLeftMargin: currentItem?.contentLeftMargin ?? 0
    readonly property int contentRightMargin: currentItem?.contentRightMargin ?? 0

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    // Currently only respected by the list view:
    property bool enableBeginningFade: true
    property bool enableEndFade: true

    property alias parentId: artistModel.parentId
    property alias searchPattern: artistModel.searchPattern
    property alias sortOrder: artistModel.sortOrder
    property alias sortCriteria: artistModel.sortCriteria

    signal artistAlbumViewRequested(var id, int reason)

    function requestArtistAlbumView(reason: int, id = null) {
        if (id !== null) {
            console.assert(id !== undefined)
            artistAlbumViewRequested(id, reason)
        } else {
            // Do not call this function if there is no current item,
            // and you are not providing an explicit id:
            console.assert(currentIndex >= 0)
            // Do not call this function if there is no model:
            console.assert(root.model)
            const data = root.model.getDataAt(currentIndex)
            artistAlbumViewRequested(data.id, reason)
        }
    }

    isSearchable: true

    model: MLArtistModel {
        id: artistModel
        ml: MediaLib
    }

    sortModel: [
        { text: qsTr("Artist A-Z"), criteria: "name", order: Qt.AscendingOrder },
        { text: qsTr("Artist Z-A"), criteria: "name", order: Qt.DescendingOrder },
        { text: qsTr("Most Tracks First"), criteria: "nb_tracks", order: Qt.DescendingOrder },
        { text: qsTr("Fewest Tracks First"), criteria: "nb_tracks", order: Qt.AscendingOrder }
    ]

    grid: gridComponent
    list: tableComponent
    emptyLabel: emptyLabelComponent

    MLContextMenu {
        id: contextMenu

        model: artistModel
    }

    MLDragItem {
        id: artistsDragItem

        view: root.currentItem
        indexes: indexesFlat ? selectionModel.selectedIndexesFlat
                             : selectionModel.selectedIndexes
        indexesFlat: !!selectionModel.selectedIndexesFlat
        defaultCover: VLCStyle.noArtArtistSmall
    }

    Component {
        id: gridComponent

        Widgets.ExpandGridItemView {
            id: artistGrid

            basePictureWidth: VLCStyle.gridCover_music_width
            basePictureHeight: VLCStyle.gridCover_music_height

            selectionModel: root.selectionModel
            model: artistModel
            focus: true

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            headerDelegate: root.header
            Navigation.parentItem: root

            onActionAtIndex: (index) => {
                if (selectionModel.selectedIndexes.length > 1) {
                    artistModel.addAndPlay( selectionModel.selectedIndexes )
                } else {
                    currentIndex = index
                    root.requestArtistAlbumView(Qt.TabFocusReason)
                }
            }

            delegate: AudioGridItem {
                id: gridItem

                width: artistGrid.cellWidth
                height: artistGrid.cellHeight

                pictureWidth: artistGrid.maxPictureWidth
                pictureHeight: artistGrid.maxPictureHeight
                image: model.cover || ""
                fallbackImage: VLCStyle.noArtArtistSmall

                title: model.name || qsTr("Unknown artist")
                subtitle: qsTr("%1 song", "%1 songs", model.nb_tracks).arg(model.nb_tracks)
                titleTopMargin: artistGrid.titleTopMargin
                dragItem: artistsDragItem

                onItemClicked: (modifier, select) => { artistGrid.leftClickOnItem(modifier, index, select) }

                onItemDoubleClicked: root.requestArtistAlbumView(Qt.MouseFocusReason, model.id)

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    artistGrid.rightClickOnItem(index)
                    contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
                }
            }
        }
    }


    Component {
        id: tableComponent

        Widgets.ListGridView {
            id: listView

            selectionModel: root.selectionModel
            model: artistModel
            focus: true

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            headerDelegate: root.header
            Navigation.parentItem: root

            onActionAtIndex: (index) => {
                if (selectionModel.selectedIndexes.length > 1) {
                    artistModel.addAndPlay( selectionModel.selectedIndexes )
                } else {
                    currentIndex = index
                    root.requestArtistAlbumView(Qt.TabFocusReason)
                }
            }

            delegate: Widgets.ListGridItem {
                required property var model
                required property int index

                width: listView.cellWidth
                height: listView.cellHeight

                image: model.cover || ""
                fallbackImage: VLCStyle.noArtArtistSmall

                title: model.name || qsTr("Unknown artist")

                dragItem: artistsDragItem

                onItemClicked: (modifier, select) => { listView.leftClickOnItem(modifier, index, select) }

                onItemDoubleClicked: root.requestArtistAlbumView(Qt.MouseFocusReason, model.id)

                onPlayClicked: artistModel.addAndPlay([artistModel.index(index, 0)])

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    listView.rightClickOnItem(index)
                    contextMenu.popup(listView.selectionModel.selectedIndexes, globalMousePos)
                }
            }
        }
    }

    Component {
        id: emptyLabelComponent

        Widgets.EmptyLabelButton {
            text: qsTr("No artists found\nPlease try adding sources")
            Navigation.parentItem: root
            cover: VLCStyle.noArtArtistCover
        }
    }
}
