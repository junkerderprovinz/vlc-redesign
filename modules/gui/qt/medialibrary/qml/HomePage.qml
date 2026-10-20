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
import QtQuick.Window
import QtQuick.Templates as T

import VLC.MediaLibrary

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Widgets.PageExt {
    id: root

    property var pagePrefix: [] // behave like a Page

    sortModel: [
        { text: qsTr("Newest First"), criteria: "insertion", order: Qt.DescendingOrder },
        { text: qsTr("Oldest First"), criteria: "insertion", order: Qt.AscendingOrder },
        { text: qsTr("Title A-Z"), criteria: "title", order: Qt.AscendingOrder },
        { text: qsTr("Title Z-A"), criteria: "title", order: Qt.DescendingOrder },
        { text: qsTr("Duration Ascending"), criteria: "duration", order: Qt.AscendingOrder },
        { text: qsTr("Duration Descending"), criteria: "duration", order: Qt.DescendingOrder }
    ]

    title: qsTr("Home")

    hasGridListMode: true

    isSearchable: true

    // number of rows a section shows in list mode
    readonly property int listRowCount: 6

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    signal seeAllButtonClicked(string name, int reason)

    function positionContentAtBeginning() {
        contentYBehavior.enabled = true
        flickable.contentY = -flickable.originY
        contentYBehavior.enabled = false
    }

    function setCurrentItemFocus(reason) {
        // `focus` is checked, because that indicates the item that has the focus within the focus scope
        const rows = [continueWatchingRow, listenAgainRow, foldersRow, playlistsRow, artistsRow,
                      streamsRow, favoritesRow, newVideoRow, newMusicRow]

        for (const row of rows) {
            if (row.focus) {
                row.setCurrentItemFocus(reason)
                return
            }
        }

        if (coneNButtons.visible)
            coneNButtons.forceActiveFocus(reason)
        else
            mediaRows.forceActiveFocus(reason)
    }

    function _positionFlickable(item) {
        contentYBehavior.enabled = true
        Helpers.positionFlickableToContainItem(flickable, item)
        contentYBehavior.enabled = false
    }

    function _currentItemOf(row) {
        // FIXME: `ExpandGridView` does not have `currentItem`.
        return row.currentItem?.currentItem ?? row.currentItem?._getItem(row.currentIndex) ?? null
    }

    contentItem: Flickable {
        id: flickable

        implicitWidth: Math.max(coneNButtons.implicitWidth, mediaRows.implicitWidth)
        implicitHeight: _hasMedias ? mediaRows.implicitHeight : coneNButtons.implicitHeight

        contentWidth: width
        contentHeight: _hasMedias ? mediaRows.implicitHeight
                                  : height - topMargin - bottomMargin

        flickableDirection: Flickable.AutoFlickIfNeeded

        boundsBehavior: Flickable.StopAtBounds

        // FIXME: make the media rows positioners consider the flickable margins when adjusting flickable `contentY`.
        bottomMargin: VLCStyle.margin_large

        pixelAligned: (MainCtx.qtVersion() >= MainCtx.qtVersionCheck(6, 2, 5)) // QTBUG-103996
                      && (Screen.pixelDensity >= VLCStyle.highPixelDensityThreshold) // no need for sub-pixel alignment with high pixel density

        property bool _hasMedias: true

        Binding on _hasMedias {
            when: !continueWatchingRow.model.loading && !listenAgainRow.model.loading
                  && !favoritesRow.model.loading && !newVideoRow.model.loading
                  && !newMusicRow.model.loading
            value: continueWatchingRow.visible || listenAgainRow.visible
                   || favoritesRow.visible || newVideoRow.visible || newMusicRow.visible
            restoreMode: Binding.RestoreNone
        }

        T.ScrollBar.vertical: Widgets.ScrollBarExt {}

        // This behavior allows to have similar "smooth" animation
        // that Qt views have with `highlightFollowsCurrentItem`.
        Behavior on contentY {
            id: contentYBehavior

            enabled: false

            // NOTE: Usage of `SmoothedAnimation` is intentional here.
            SmoothedAnimation {
                duration: VLCStyle.duration_veryLong
                easing.type: Easing.InOutSine
            }
        }

        property Component implicitFlickableScrollHandler: DefaultFlickableScrollHandler { }

        // NOTE: This property can be set to null to prevent using a scroll handler:
        property FlickableScrollHandler scrollHandler: {
            if (interactive) {
                // JS ownership:
                return implicitFlickableScrollHandler.createObject(null, { target: flickable })
            } else {
                return null
            }
        }

        Component.onCompleted: {
            if (!usingTouch) {
                // Flickable filters child mouse events for flicking (even when
                // the delegate is grabbed). However, this is not a useful
                // feature for non-touch cases, so disable it here and enable
                // it if touch is detected through the hover handler:
                MainCtx.setFiltersChildMouseEvents(flickable, false)
            }
        }

        readonly property bool usingTouch: MainCtx.usingTouch

        onUsingTouchChanged: {
            if (usingTouch)
                MainCtx.setFiltersChildMouseEvents(flickable, true)
            // We do not disable filtering child mouse events
            // because Qt currently has a bug that the flickable
            // jumps when it is enabled again later on.
        }

        // Open actions for an empty library; with media, the same actions
        // stay in the main menu.
        NoMedialibHome.ConeNButtons {
            id: coneNButtons

            focus: !flickable._hasMedias

            visible: !flickable._hasMedias

            orientation: Qt.Vertical

            anchors.centerIn: parent

            Navigation.parentItem: root
            Navigation.upItem: root.header
        }

        Widgets.NavigableCol {
            id: mediaRows

            focus: flickable._hasMedias

            visible: flickable._hasMedias

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0 // NOTE: We depend on the top padding of view header currently.

            Navigation.parentItem: root
            Navigation.upItem: root.header

            Widgets.ViewHeader {
                visible: continueWatchingRow.visible
                text: qsTr("Continue Watching")
                view: continueWatchingRow
                topPadding: VLCStyle.dp(20, VLCStyle.scale)
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    root.seeAllButtonClicked("continueWatching", reason)
                }
            }

            VideoAll {
                id: continueWatchingRow

                AccessibleCompat.id: "continueWatching"

                anchors.left: parent.left
                anchors.right: parent.right

                height: currentItem?.contentHeight ?? implicitHeight

                visible: model.count !== 0

                interactive: false

                emptyLabel: null

                // FIXME: `ExpandGridView` causes extreme performance degradation when `reuseItems`
                //        is true and items provided by the model change (#29084).
                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLRecentVideoModel {
                    ml: MediaLib

                    sortCriteria: root.sort.criteria
                    sortOrder: root.sort.order
                    searchPattern: root.search.pattern

                    // FIXME: Make limit 0 load no items, instead of loading all items.
                    limit: Math.max(continueWatchingRow.currentItem?.nbItemPerRow ?? null, 1)
                }

                contextMenu: MLContextMenu {
                    model: continueWatchingRow.model

                    showPlayAsAudioAction: true
                }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(root._currentItemOf(this) ?? this)
                onCurrentIndexChanged: {
                    const item = root._currentItemOf(this)
                    if (activeFocus && item)
                        root._positionFlickable(item)
                }
            }

            Widgets.ViewHeader {
                visible: listenAgainRow.visible
                text: qsTr("Listen Again")
                view: listenAgainRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    root.seeAllButtonClicked("listenAgain", reason)
                }
            }

            MediaView {
                id: listenAgainRow

                AccessibleCompat.id: "listenAgain"

                anchors.left: parent.left
                anchors.right: parent.right

                height: currentItem?.contentHeight ?? implicitHeight

                visible: model.count !== 0

                interactive: false

                emptyLabel: null

                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLRecentAudioModel {
                    ml: MediaLib

                    searchPattern: root.search.pattern

                    limit: root.gridMode ? Math.max(listenAgainRow.currentItem?.nbItemPerRow ?? null, 1)
                                            : root.listRowCount
                }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(root._currentItemOf(this) ?? this)
                onCurrentIndexChanged: {
                    const item = root._currentItemOf(this)
                    if (activeFocus && item)
                        root._positionFlickable(item)
                }
            }

            Widgets.ViewHeader {
                visible: foldersRow.visible
                text: qsTr("Folders")
                view: foldersRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    MainCtx.grouping = MainCtx.GROUPING_FOLDER
                    History.push(["video", "all"], reason)
                }
            }

            HomeTileRow {
                id: foldersRow

                AccessibleCompat.id: "folders"

                model: MLVideoFoldersModel {
                    ml: MediaLib

                    searchPattern: root.search.pattern

                    limit: Math.max(foldersRow.nbItemPerRow, 1)
                }

                fallbackSource: "qrc:///sd/directory.svg"
                iconText: VLCIcons.folder

                Navigation.parentItem: mediaRows

                onPositionRequested: (item) => root._positionFlickable(item)

                function open(model, reason) {
                    History.push(["video", "all", "group"], { parentId: model.id, title: model.title }, reason)
                }
            }

            Widgets.ViewHeader {
                visible: playlistsRow.visible
                text: qsTr("Playlists")
                view: playlistsRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    History.push(["playlists"], reason)
                }
            }

            HomeTileRow {
                id: playlistsRow

                AccessibleCompat.id: "playlists"

                model: MLPlaylistListModel {
                    ml: MediaLib

                    searchPattern: root.search.pattern

                    limit: Math.max(playlistsRow.nbItemPerRow, 1)
                }

                titleRole: "name"
                coverRole: "thumbnail"
                fallbackSource: "qrc:///sd/playlist.svg"
                iconText: VLCIcons.playlist

                Navigation.parentItem: mediaRows

                onPositionRequested: (item) => root._positionFlickable(item)

                function open(model, reason) {
                    History.push(["playlists", "list"], { parentId: model.id, title: model.name }, reason)
                }
            }

            Widgets.ViewHeader {
                visible: artistsRow.visible
                text: qsTr("Artists")
                view: artistsRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    History.push(["music", "artists"], reason)
                }
            }

            HomeTileRow {
                id: artistsRow

                AccessibleCompat.id: "artists"

                model: MLArtistModel {
                    ml: MediaLib

                    searchPattern: root.search.pattern

                    sortCriteria: "nb_tracks"
                    sortOrder: Qt.DescendingOrder

                    limit: Math.max(artistsRow.nbItemPerRow, 1)
                }

                titleRole: "name"
                coverRole: "cover"
                fallbackImage: VLCStyle.noArtArtistSmall
                iconText: VLCIcons.artist

                Navigation.parentItem: mediaRows

                onPositionRequested: (item) => root._positionFlickable(item)

                function open(model, reason) {
                    History.push(["music", "artists", "albums"], { artistId: model.id }, reason)
                }
            }

            Widgets.ViewHeader {
                visible: streamsRow.visible
                text: qsTr("Latest Streams")
                view: streamsRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    History.push(["discover", "url"], reason)
                }
            }

            Widgets.ListGridView {
                id: streamsRow

                AccessibleCompat.id: "latestStreams"

                anchors.left: parent.left
                anchors.right: parent.right

                height: contentHeight

                visible: model.count !== 0

                interactive: false

                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLUrlModel {
                    ml: MediaLib

                    searchPattern: root.search.pattern

                    limit: Math.max(streamsRow.nbItemPerRow, 1) * 2
                }

                delegate: Widgets.ListGridItem {
                    required property var model
                    required property int index

                    width: streamsRow.cellWidth
                    height: streamsRow.cellHeight

                    iconText: VLCIcons.streaming
                    title: model.url

                    showContextButton: false

                    onItemClicked: (modifier, select) => { streamsRow.leftClickOnItem(modifier, index, select) }
                    onItemDoubleClicked: MediaLib.addAndPlay(model.id)
                    onPlayClicked: MediaLib.addAndPlay(model.id)
                }

                onActionAtIndex: (index) => { streamsRow.model.addAndPlay(streamsRow.selectionModel.selectedIndexes) }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(this)
            }

            Widgets.ViewHeader {
                visible: favoritesRow.visible
                text: qsTr("Favorites")
                view: favoritesRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    root.seeAllButtonClicked("favorites", reason)
                }
            }

            MediaView {
                id: favoritesRow

                AccessibleCompat.id: "favourites"

                anchors.left: parent.left
                anchors.right: parent.right

                height: currentItem?.contentHeight ?? implicitHeight

                visible: model.count !== 0

                interactive: false

                emptyLabel: null

                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLMediaModel {
                    favoriteOnly: true

                    ml: MediaLib

                    sortCriteria: root.sort.criteria || "insertion"
                    sortOrder: root.sort.order
                    searchPattern: root.search.pattern

                    // FIXME: Make limit 0 load no items, instead of loading all items.
                    limit: root.gridMode ? Math.max(favoritesRow.currentItem?.nbItemPerRow ?? null, 1)
                                            : root.listRowCount
                }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(root._currentItemOf(this) ?? this)
                onCurrentIndexChanged: {
                    const item = root._currentItemOf(this)
                    if (activeFocus && item)
                        root._positionFlickable(item)
                }
            }

            Widgets.ViewHeader {
                text: qsTr("New Videos")
                visible: newVideoRow.visible
                view: newVideoRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    root.seeAllButtonClicked("newVideo", reason)
                }
            }

            VideoAll {
                id: newVideoRow

                AccessibleCompat.id: "newVideo"

                anchors.left: parent.left
                anchors.right: parent.right

                height: currentItem?.contentHeight ?? implicitHeight

                visible: model.count !== 0

                interactive: false

                emptyLabel: null

                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLVideoModel {
                    ml: MediaLib

                    sortCriteria: root.sort.criteria || "insertion"
                    sortOrder: root.sort.order
                    searchPattern: root.search.pattern

                    // FIXME: Make limit 0 load no items, instead of loading all items.
                    limit: root.gridMode ? Math.max(newVideoRow.currentItem?.nbItemPerRow ?? null, 1)
                                            : root.listRowCount
                }

                contextMenu: MLContextMenu {
                    model: newVideoRow.model

                    showPlayAsAudioAction: true
                }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(root._currentItemOf(this) ?? this)
                onCurrentIndexChanged: {
                    const item = root._currentItemOf(this)
                    if (activeFocus && item)
                        root._positionFlickable(item)
                }
            }

            Widgets.ViewHeader {
                text: qsTr("New Music")
                visible: newMusicRow.visible
                view: newMusicRow
                seeAllButton.visible: true

                onSeeAllButtonClicked: function (reason) {
                    root.seeAllButtonClicked("newMusic", reason)
                }
            }

            MediaView {
                id: newMusicRow

                AccessibleCompat.id: "newMusic"

                anchors.left: parent.left
                anchors.right: parent.right

                height: currentItem?.contentHeight ?? implicitHeight

                visible: model.count !== 0

                interactive: false

                emptyLabel: null

                reuseItems: false

                Navigation.parentItem: mediaRows

                model: MLAudioModel {
                    ml: MediaLib

                    sortCriteria: root.sort.criteria || "insertion"
                    sortOrder: root.sort.order
                    searchPattern: root.search.pattern

                    // FIXME: Make limit 0 load no items, instead of loading all items.
                    limit: root.gridMode ? Math.max(newMusicRow.currentItem?.nbItemPerRow ?? null, 1)
                                            : root.listRowCount
                }

                onActiveFocusChanged: if (activeFocus) root._positionFlickable(root._currentItemOf(this) ?? this)
                onCurrentIndexChanged: {
                    const item = root._currentItemOf(this)
                    if (activeFocus && item)
                        root._positionFlickable(item)
                }
            }
        }
    }

    // A row of library entities shown on the home page, as square tiles or as compact rows.
    component HomeTileRow: MainViewLoader {
        id: tileRow

        property string titleRole: "title"
        property string coverRole: ""
        property string fallbackSource: ""
        property string fallbackImage: ""
        property string iconText: ""

        readonly property int nbItemPerRow: currentItem?.nbItemPerRow ?? 1

        readonly property int contentLeftMargin: currentItem?.contentLeftMargin ?? 0
        readonly property int contentRightMargin: currentItem?.contentRightMargin ?? 0

        readonly property string _fallback: {
            if (fallbackSource === "")
                return fallbackImage

            return SVGColorImage.colorize(fallbackSource)
                                .color1(tileRow.colorContext.fg.primary)
                                .accent(tileRow.colorContext.accent)
                                .uri()
        }

        signal positionRequested(Item item)

        function open(model, reason) {}

        function play(indexes) {
            model.addAndPlay(indexes)
        }

        function _actionAtIndex(index) {
            if (selectionModel.selectedIndexes.length > 1)
                play(selectionModel.selectedIndexes)
            else
                open(model.getDataAt(index), Qt.TabFocusReason)
        }

        anchors.left: parent.left
        anchors.right: parent.right

        height: currentItem?.contentHeight ?? implicitHeight

        visible: model.count !== 0

        emptyLabel: null

        onActiveFocusChanged: if (activeFocus) positionRequested(currentItem?._getItem(currentIndex) ?? tileRow)

        readonly property int currentIndex: currentItem?.currentIndex ?? -1

        onCurrentIndexChanged: {
            const item = currentItem?._getItem(currentIndex)
            if (activeFocus && item)
                positionRequested(item)
        }

        grid: Component {
            Widgets.ExpandGridItemView {
                id: gridView

                model: tileRow.model
                selectionModel: tileRow.selectionModel

                interactive: false
                reuseItems: false

                basePictureWidth: VLCStyle.gridCover_music_width
                basePictureHeight: VLCStyle.gridCover_music_height

                subtitleHeight: 0

                Navigation.parentItem: tileRow

                onActionAtIndex: (index) => tileRow._actionAtIndex(index)

                delegate: Widgets.GridItem {
                    required property var model
                    required property int index

                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    pictureWidth: gridView.maxPictureWidth
                    pictureHeight: gridView.maxPictureHeight

                    fillMode: Image.PreserveAspectCrop

                    image: (tileRow.coverRole !== "" ? model[tileRow.coverRole] : "") || ""
                    fallbackImage: tileRow._fallback

                    title: model[tileRow.titleRole] || qsTr("Unknown title")

                    onItemClicked: (modifier, select) => { gridView.leftClickOnItem(modifier, index, select) }

                    onItemDoubleClicked: tileRow.open(model, Qt.MouseFocusReason)

                    onPlayClicked: tileRow.play([tileRow.model.index(index, 0)])
                }
            }
        }

        list: Component {
            Widgets.ListGridView {
                id: listView

                model: tileRow.model
                selectionModel: tileRow.selectionModel

                interactive: false
                reuseItems: false

                Navigation.parentItem: tileRow

                onActionAtIndex: (index) => tileRow._actionAtIndex(index)

                delegate: Widgets.ListGridItem {
                    required property var model
                    required property int index

                    width: listView.cellWidth
                    height: listView.cellHeight

                    iconText: tileRow.iconText
                    image: (tileRow.iconText === "" && tileRow.coverRole !== "" ? model[tileRow.coverRole] : "") || ""
                    fallbackImage: tileRow._fallback

                    title: model[tileRow.titleRole] || qsTr("Unknown title")

                    dimmed: tileRow.iconText !== ""
                    showContextButton: false

                    onItemClicked: (modifier, select) => { listView.leftClickOnItem(modifier, index, select) }

                    onItemDoubleClicked: tileRow.open(model, Qt.MouseFocusReason)

                    onPlayClicked: tileRow.play([tileRow.model.index(index, 0)])
                }
            }
        }
    }
}
