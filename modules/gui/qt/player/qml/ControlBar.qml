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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQml.Models


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Player
import VLC.PlayerControls
import VLC.Util

T.Pane {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: VLCStyle.dp(11, VLCStyle.scale)
    bottomPadding: VLCStyle.dp(11, VLCStyle.scale)

    readonly property real sliderY: 0
    property int identifier: -1
    property real bookmarksHeight: VLCStyle.controlBarBookmarksHeight

    // Without a seek bar in the layout, the bar shows one in a row of its own.
    readonly property bool inlinePosition: contentItem.playerControlLayout.hasPositionWidget

    property var menu: undefined

    signal requestLockUnlockAutoHide(bool lock)

    ///incomming signal to request all menu and popup to close
    signal forceUnlock()

    enabled: visible

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => root.Navigation.defaultKeyAction(event)
    Navigation.cancelAction: function() { History.previous(Qt.BacktabFocusReason) }

    Accessible.name: qsTr("Player controls")
    AccessibleCompat.id: "playerControlBar"

    function showChapterMarks() {
        contentItem.positionWidget.slider.showChapterMarks()
    }

    function applyMenu(menu) {
        if (root.menu === menu)
            return

        // NOTE: When applying a new menu we hide the previous one.
        if (menu)
            dismiss()

        root.menu = menu
    }

    function dismiss() {
        if ((typeof menu === undefined) || !menu)
            return
        if (menu.hasOwnProperty("dismiss"))
            menu.dismiss()
        else if (menu.hasOwnProperty("close"))
            menu.close()
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background: Rectangle {
        color: theme.tokens.bgA3Glass

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: VLCStyle.dp(1, VLCStyle.scale)
            color: theme.separator
        }
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(22, VLCStyle.scale)

        property alias positionWidget: positionWidget

        property alias playerControlLayout: playerControlLayout

        readonly property list<Item> strayItems: [
            Loader {
                id: bookmarksLoader

                parent: root
                active: MainCtx.mediaLibraryAvailable && !root.inlinePosition
                source: "qrc:///qt/qml/VLC/MediaLibrary/Bookmarks.qml"

                x: root.leftPadding + positionWidget.x + positionWidget.slider.x
                y: root.topPadding + positionWidget.y + positionWidget.height + VLCStyle.margin_xxsmall
                width: positionWidget.slider.width

                onLoaded: {
                   item.barHeight = Qt.binding(function() { return bookmarksHeight })
                   item.controlBarHovered = Qt.binding(function() { return root.hovered })
                   item.yShift = Qt.binding(function() { return positionWidget.height + VLCStyle.margin_xxsmall })
                }
            }
        ]

        PositionWidget {
            id: positionWidget

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

            visible: !root.inlinePosition
            focus: visible

            Navigation.parentItem: root
            Navigation.downItem: playerControlLayout
        }

        PlayerControlLayout {
            id: playerControlLayout

            Layout.fillWidth: true
            Layout.fillHeight: true

            identifier: root.identifier

            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

            visible: !model?.empty ?? false

            Navigation.upItem: (positionWidget.visible && positionWidget.slider.enabled) ? positionWidget
                                                                                         : root.Navigation.upItem

            onRequestLockUnlockAutoHide: (lock) => root.requestLockUnlockAutoHide(lock)

            onMenuOpened: (menu) => root.applyMenu(menu)

            Component.onCompleted: {
                root.forceUnlock.connect(playerControlLayout.forceUnlock)
            }
        }
    }
}
