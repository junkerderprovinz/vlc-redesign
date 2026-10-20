/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
 *
 * Authors: Benjamin Arnaud <bunjee@omega.gg>
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


import VLC.Style
import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Network

FocusScope {
    id: root

    // Properties

    required property BaseModel model

    readonly property int rowHeight: _currentView?.rowHeight ?? 0

    readonly property int contentHeight: _currentView?.contentHeight ?? 0

    readonly property int contentLeftMargin: _currentView?.contentLeftMargin ?? 0
    readonly property int contentRightMargin: _currentView?.contentRightMargin ?? 0

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    readonly property int currentIndex: _currentView?.currentIndex ?? -1

    property int maximumRows: -1

    readonly property int maximumCount: _currentView?.maximumCount ?? -1

    readonly property int nbItemPerRow: _currentView?.nbItemPerRow ?? 1

    property bool isSearchable: true

    readonly property bool hasGridListMode: true

    // The library panel beside the player is too narrow for the grid.
    readonly property bool gridMode: MainCtx.gridView && !MainCtx.playerView

    property bool interactive: true

    property bool reuseItems: true

    // Aliases

    property alias leftPadding: loader.anchors.leftMargin
    property alias rightPadding: loader.anchors.rightMargin

    // Private

    property alias _currentView: loader.item

    // Signals

    signal browse(var tree, int reason)

    signal seeAll(int reason)

    // Events

    onFocusChanged: {
        if (activeFocus === false || model.count === 0 || model.currentIndex !== -1)
            return

        model.currentIndex = 0
    }

    // Connections

    // Functions

    function playAt(index) {
        model.addAndPlay(index)
    }

    function setCurrentItemFocus(reason) {
        _currentView.setCurrentItemFocus(reason)
    }

    function getItemY(index) {
        if (_currentView === null)
            return 0

        return _currentView.getItemY(index)
    }

    // Events

    function onAction(index) {
        const indexes = modelSelect.selectedIndexes

        if (indexes.length > 1) {
            model.addAndPlay(indexes)

            return
        }

        const data = model.getDataAt(index)

        const type = data.type

        if (type === NetworkMediaModel.TYPE_DIRECTORY
                || type === NetworkMediaModel.TYPE_NODE
                || type === NetworkMediaModel.TYPE_PLAYLIST)
            browse(data.tree, Qt.TabFocusReason)
        else
            playAt(index);
    }

    function onClicked(model, index, modifier, select) {
        if (select)
            modelSelect.updateSelection(modifier, model.currentIndex, index)

        _currentView.currentIndex = index

        _currentView.currentItem.forceActiveFocus(Qt.MouseFocusReason)
    }

    function onDoubleClicked(model, index) {
        const type = model.type

        if (type === NetworkMediaModel.TYPE_NODE
                || type === NetworkMediaModel.TYPE_DIRECTORY
                || type === NetworkMediaModel.TYPE_PLAYLIST)
            browse(model.tree, Qt.MouseFocusReason)
        else
            playAt(index);
    }

    // Children

    ListSelectionModel {
        id: modelSelect

        model: root.model
    }

    Loader {
        id: loader

        anchors.fill: parent

        focus: (model.count !== 0)

        sourceComponent: root.gridMode ? grid : list
    }

    Component {
        id: grid

        Widgets.ExpandGridItemView {
            id: gridView

            basePictureWidth: VLCStyle.gridCover_network_width
            basePictureHeight: VLCStyle.gridCover_network_height

            maxNbItemPerRow: 12

            readonly property int maximumCount: (root.maximumRows === -1)
                                                ? -1
                                                : root.maximumRows * nbItemPerRow

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            model: root.model

            selectionModel: modelSelect

            interactive: root.interactive

            reuseItems: root.reuseItems

            Navigation.parentItem: root

            onActionAtIndex: (index) => { root.onAction(index) }

            delegate: NetworkGridItem {
                width: gridView.cellWidth;
                height: gridView.cellHeight;

                pictureWidth: gridView.maxPictureWidth
                pictureHeight: gridView.maxPictureHeight

                onItemClicked: (modifier, select) => { root.onClicked(model, index, modifier, select) }

                onItemDoubleClicked: root.onDoubleClicked(model, index)

                onPlayClicked: root.playAt(index)
            }
        }
    }

    Component {
        id: list

        Widgets.ListGridView {
            id: listView

            // Properties

            readonly property int maximumCount: (root.maximumRows === -1)
                                                ? -1
                                                : root.maximumRows * nbItemPerRow

            // Settings

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            model: root.model

            selectionModel: modelSelect

            interactive: root.interactive

            reuseItems: root.reuseItems

            Navigation.parentItem: root

            onActionAtIndex: (index) => { root.onAction(index) }

            delegate: Widgets.ListGridItem {
                required property var model
                required property int index

                readonly property bool isContainer: model.type === NetworkMediaModel.TYPE_NODE
                                                    || model.type === NetworkMediaModel.TYPE_DIRECTORY
                                                    || model.type === NetworkMediaModel.TYPE_PLAYLIST

                width: listView.cellWidth
                height: listView.cellHeight

                image: model.artwork ?? ""
                fallbackImage: SVGColorImage.colorize(model.artworkFallback)
                                            .color1(colorContext.fg.primary)
                                            .accent(colorContext.accent)
                                            .uri()

                title: model.name || qsTr("Unknown share")

                dimmed: isContainer

                showContextButton: false

                onItemClicked: (modifier, select) => { root.onClicked(model, index, modifier, select) }

                onItemDoubleClicked: root.onDoubleClicked(model, index)

                onPlayClicked: root.playAt(index)
            }
        }
    }
}
