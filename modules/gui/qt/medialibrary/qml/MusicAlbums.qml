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

import VLC.MediaLibrary

import VLC.Util
import VLC.Widgets as Widgets
import VLC.MainInterface
import VLC.Style

MainViewLoader {
    id: root

    // Properties

    readonly property var currentIndex: currentItem?.currentIndex ?? - 1

    property Component header: null
    readonly property Item headerItem: currentItem?.headerItem ?? null

    readonly property int contentLeftMargin: currentItem?.contentLeftMargin ?? 0
    readonly property int contentRightMargin: currentItem?.contentRightMargin ?? 0

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    // Currently only respected by the list view:
    property bool enableBeginningFade: true
    property bool enableEndFade: true

    property alias parentId: albumModelId.parentId
    property alias searchPattern: albumModelId.searchPattern
    property alias sortOrder: albumModelId.sortOrder
    property alias sortCriteria: albumModelId.sortCriteria

    isSearchable: true
    model: albumModelId

    sortModel: [
        { text: qsTr("Newest First"), criteria: "release_year", order: Qt.DescendingOrder },
        { text: qsTr("Oldest First"), criteria: "release_year", order: Qt.AscendingOrder },
        { text: qsTr("Title A-Z"), criteria: "title", order: Qt.AscendingOrder },
        { text: qsTr("Title Z-A"), criteria: "title", order: Qt.DescendingOrder },
        { text: qsTr("Artist A-Z"), criteria: "main_artist", order: Qt.AscendingOrder },
        { text: qsTr("Artist Z-A"), criteria: "main_artist", order: Qt.DescendingOrder },
        { text: qsTr("Duration Ascending"), criteria: "duration", order: Qt.AscendingOrder },
        { text: qsTr("Duration Descending"), criteria: "duration", order: Qt.DescendingOrder }
    ]

    grid: gridComponent
    list: tableComponent
    emptyLabel: emptyLabelComponent

    onParentIdChanged: resetFocus()

    function _actionAtIndex(index) {
        if (selectionModel.selectedIndexes.length > 1) {
            model.addAndPlay( selectionModel.selectedIndexes )
        } else {
            model.addAndPlay( new Array(index) )
        }
    }

    MLAlbumModel {
        id: albumModelId

        ml: MediaLib
    }

    MLDragItem {
        id: albumDragItem

        view: root.currentItem
        indexes: indexesFlat ? selectionModel.selectedIndexesFlat
                             : selectionModel.selectedIndexes
        indexesFlat: !!selectionModel.selectedIndexesFlat
        defaultCover: VLCStyle.noArtAlbumCover
    }

    MLContextMenu {
        id: contextMenu

        model: albumModelId
    }

    Component {
        id: gridComponent

        Widgets.ExpandGridItemView {
            id: gridView_id

            basePictureWidth: VLCStyle.gridCover_music_width
            basePictureHeight: VLCStyle.gridCover_music_height

            activeFocusOnTab:true

            headerDelegate: root.header

            selectionModel: root.selectionModel
            model: albumModelId

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            delegate: AudioGridItem {
                id: audioGridItem

                width: gridView_id.cellWidth;
                height: gridView_id.cellHeight;

                pictureWidth: gridView_id.maxPictureWidth
                pictureHeight: gridView_id.maxPictureHeight

                opacity: gridView_id.expandIndex !== -1 && gridView_id.expandIndex !== audioGridItem.index ? .7 : 1
                dragItem: albumDragItem
                onItemClicked : (modifier, select) => { gridView_id.leftClickOnItem(modifier, index, select) }

                onItemDoubleClicked: {
                    gridView_id.switchExpandItem(index)
                }

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    gridView_id.rightClickOnItem(index)
                    contextMenu.popup(selectionModel.selectedIndexes, globalMousePos, {
                        "information": index
                    })
                }

                Behavior on opacity {
                    OpacityAnimator {
                        duration: VLCStyle.duration_short
                    }
                }
            }

            expandDelegate: MusicAlbumsGridExpandDelegate {
                id: expandDelegateId

                x: 0
                width: gridView_id.width
                onRetract: gridView_id.retract()
                Navigation.parentItem: root

                Navigation.cancelAction: function() {
                    gridView_id.setCurrentItemFocus(Qt.TabFocusReason);
                }

                Navigation.upAction: function() {
                    gridView_id.setCurrentItemFocus(Qt.TabFocusReason);
                }

                Navigation.downAction: function() {}
            }

            onActionAtIndex: (index) => {
                if (selectionModel.selectedIndexes.length === 1) {
                    switchExpandItem(index);

                    expandItem.setCurrentItemFocus(Qt.TabFocusReason);
                } else {
                    _actionAtIndex(index);
                }
            }

            Navigation.parentItem: root

            Connections {
                target: contextMenu
                function onShowMediaInformation(index) {
                    gridView_id.switchExpandItem( index )
                }
            }
        }
    }

    Component {
        id: tableComponent

        Widgets.ListGridView {
            id: listView

            model: albumModelId
            selectionModel: root.selectionModel
            headerDelegate: root.header

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            Navigation.parentItem: root

            onActionAtIndex: (index) => { _actionAtIndex(albumModelId.index(index, 0)) }

            delegate: Widgets.ListGridItem {
                required property var model
                required property int index

                width: listView.cellWidth
                height: listView.cellHeight

                image: model.cover || ""
                fallbackImage: VLCStyle.noArtAlbumCover

                title: {
                    const title = model.title || qsTr("Unknown title")
                    return model.main_artist ? qsTr("%1 - %2").arg(title).arg(model.main_artist) : title
                }

                dragItem: albumDragItem

                onItemClicked: (modifier, select) => { listView.leftClickOnItem(modifier, index, select) }

                onItemDoubleClicked: MediaLib.addAndPlay(model.id)

                onPlayClicked: MediaLib.addAndPlay(model.id)

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
            text: qsTr("No albums found\nPlease try adding sources")
            Navigation.parentItem: root
            cover: VLCStyle.noArtAlbumCover
        }
    }
}
