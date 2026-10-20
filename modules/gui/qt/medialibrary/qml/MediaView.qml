/******************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * Author: Ash <ashutoshv191@gmail.com>
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
 ******************************************************************************/
import QtQuick

import VLC.MediaLibrary

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Util
import VLC.Style

// NOTE: This is a customizable view that can be used with
//       the `MLMediaModel` and its drivatives.
// TODO: Investigate and derive `VideoAll` from `MediaView`.
MainViewLoader {
    id: root

    Accessible.role: Accessible.Pane
    Accessible.name: qsTr("Media view")
    AccessibleCompat.id: "mediaView"

    property int gridCoverWidth: VLCStyle.gridCover_music_width
    property int gridCoverHeight: VLCStyle.gridCover_music_height

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    property bool interactive: true // false, when as a row

    property bool reuseItems: true

    property bool seeAllButtonVisible: model.maximumCount > model.count

    readonly property int currentIndex: currentItem?.currentIndex ?? -1

    readonly property int rowHeight: currentItem?.rowHeight ?? 0

    readonly property int contentLeftMargin: currentItem?.contentLeftMargin ?? 0
    readonly property int contentRightMargin: currentItem?.contentRightMargin ?? 0

    isSearchable: true

    sortModel: [
        { text: qsTr("Newest First"), criteria: "insertion", order: Qt.DescendingOrder },
        { text: qsTr("Oldest First"), criteria: "insertion", order: Qt.AscendingOrder },
        { text: qsTr("Title A-Z"), criteria: "title", order: Qt.AscendingOrder },
        { text: qsTr("Title Z-A"), criteria: "title", order: Qt.DescendingOrder },
        { text: qsTr("Duration Ascending"), criteria: "duration", order: Qt.AscendingOrder },
        { text: qsTr("Duration Descending"), criteria: "duration", order: Qt.DescendingOrder }
    ]

    list: listComponent
    grid: gridComponent
    emptyLabel: emptyLabelComponent


    signal seeAllButtonClicked(int reason)


    function getItemY(index) {
        return currentItem?.getItemY(index) ?? 0
    }

    function _onItemDoubleClicked(model) {
        MediaLib.addAndPlay(model.id)
        History.push(["player"])
    }

    function _onActionAtIndex() {
        model.addAndPlay(selectionModel.selectedIndexes)
        History.push(["player"])
    }

    function _play(model) {
        if (model.id !== undefined) {
            MediaLib.addAndPlay(model.id)
            if (model.isVideo)
                MainCtx.requestShowPlayerView()
        }
    }


    MLDragItem {
        id: dragItemId

        view: root.currentItem

        coverRole: "small_cover"

        defaultCover: VLCStyle.noArtAlbumCover // TODO: better fallback image
                                               // use a better vlc branding fallback image like 'noart.png' which is used in vlc 3 for media

        indexesFlat: !!root.selectionModel.selectedIndexesFlat

        indexes: indexesFlat ? root.selectionModel.selectedIndexesFlat : root.selectionModel.selectedIndexes
    }

    MLContextMenu {
        id: contextMenu

        model: root.model
    }

    Component {
        id: gridComponent

        Widgets.ExpandGridItemView {
            id: gridView

            focus: true

            model: root.model

            selectionModel: root.selectionModel

            basePictureWidth: root.gridCoverWidth
            basePictureHeight: root.gridCoverHeight

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            interactive: root.interactive

            reuseItems: root.reuseItems

            Navigation.parentItem: root

            delegate: Widgets.GridItem {
                id: gridDelegate

                required property int index
                required property var model

                // TODO: Investigate if it makes sense to use `sourceClipRect`
                //       instead of setting `fillMode` to preserve aspect crop.
                width: gridView.cellWidth
                height: gridView.cellHeight

                pictureWidth: gridView.maxPictureWidth
                pictureHeight: gridView.maxPictureHeight

                fillMode: Image.PreserveAspectCrop

                image: model.small_cover ?? ""
                fallbackImage: model.isVideo ? VLCStyle.noArtVideoCover : VLCStyle.noArtAlbumCover

                title: model.title || qsTr("Unknown Title")
                subtitle: model.main_artist ?? ""

                opacity: gridView.expandIndex !== -1 && gridView.expandIndex !== index ? 0.7 : 1

                dragItem: dragItemId

                onPlayClicked: root._play(model)

                onItemDoubleClicked: root._onItemDoubleClicked(model)

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    gridView.rightClickOnItem(index)
                    contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
                }

                onItemClicked: (modifier, select) => {
                    gridView.leftClickOnItem(modifier, index, select)
                }

                Behavior on opacity {
                    OpacityAnimator {
                        duration: VLCStyle.duration_short
                    }
                }
            }

            onActionAtIndex: root._onActionAtIndex()
        }
    }

    Component {
        id: listComponent

        Widgets.ListGridView {
            id: listView

            focus: true

            model: root.model

            selectionModel: root.selectionModel

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            interactive: root.interactive

            reuseItems: root.reuseItems

            Navigation.parentItem: root

            delegate: Widgets.ListGridItem {
                required property int index
                required property var model

                width: listView.cellWidth
                height: listView.cellHeight

                image: model.small_cover ?? ""
                fallbackImage: model.isVideo ? VLCStyle.noArtVideoCover : VLCStyle.noArtAlbumCover

                title: {
                    const title = model.title || qsTr("Unknown Title")
                    return model.main_artist ? qsTr("%1 - %2").arg(title).arg(model.main_artist) : title
                }

                progress: Helpers.clamp(model.progress ?? 0, 0, 1)

                current: Player.isStarted && !!model.mrl
                         && model.mrl.toString() === Player.url.toString()

                dragItem: dragItemId

                onPlayClicked: root._play(model)

                onItemDoubleClicked: root._onItemDoubleClicked(model)

                onContextMenuButtonClicked: (_, globalMousePos) => {
                    listView.rightClickOnItem(index)
                    contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
                }

                onItemClicked: (modifier, select) => {
                    listView.leftClickOnItem(modifier, index, select)
                }
            }

            onActionAtIndex: root._onActionAtIndex()
        }
    }

    Component {
        id: emptyLabelComponent

        Widgets.EmptyLabelButton {
            focus: true

            cover: VLCStyle.noArtAlbumCover // TODO: better fallback image

            text: qsTr("No media found\nPlease try adding sources")

            Navigation.parentItem: root
        }
    }
}
