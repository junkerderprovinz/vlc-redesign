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

        Widgets.TableViewExt {
            id: recentView

            anchors.fill: parent

            visible: recentModel.count > 0
            focus: recentModel.count > 0

            model: recentModel

            sortModel: [{
                weight: 1,

                model: {
                    criteria: "title",

                    text: qsTr("Title"),

                    isSortable: false,

                    placeHolder: VLCStyle.noArtVideoCover,

                    headerDelegate: tableColumns.titleHeaderDelegate,
                    colDelegate: tableColumns.titleDelegate
                }
            }, {
                weight: 1,

                model: {
                    criteria: "url",

                    text: qsTr("Location"),

                    isSortable: false
                }
            }, {
                size: 1,

                model: {
                    criteria: "duration",

                    text: qsTr("Duration"),

                    isSortable: false,

                    showContextButton: true,

                    headerDelegate: tableColumns.timeHeaderDelegate,
                    colDelegate: tableColumns.timeColDelegate
                }
            }]

            rowHeight: VLCStyle.tableCoverRow_height

            rowContextMenu: contextMenu

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd

            fadingEdge.enableBeginningFade: root.enableBeginningFade
            fadingEdge.enableEndFade: root.enableEndFade

            onActionForSelection: (selection) => recentModel.addAndPlay(selection)
            onItemDoubleClicked: (index, model) => MediaLib.addAndPlay(model.id)

            onRightClick: (_, _, globalMousePos) => {
                contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
            }

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

    MLTableColumns {
        id: tableColumns

        criteriaCover: "small_cover"
    }
}
