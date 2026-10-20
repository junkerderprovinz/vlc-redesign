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
import QtQuick.Window


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Util


Item {
    id: thumbnail

    implicitWidth: VLCStyle.dp(50, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

    property bool paintOnly: false

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.ToolButton
    }

    Rectangle {
        anchors.fill: parent

        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: theme.bg.secondary

        visible: image.status !== Image.Ready
    }

    Widgets.ImageExt {
        id: image

        anchors.fill: parent

        source: (!thumbnail.paintOnly && Player.artwork && Player.artwork.toString())
                ? VLCAccessImage.uri(Player.artwork) : ""
        sourceSize.height: height * MainCtx.effectiveDevicePixelRatio(Window.window)
        fillMode: Image.PreserveAspectCrop
        radius: VLCStyle.dp(4, VLCStyle.scale)

        asynchronous: true
    }

    Accessible.name: qsTr("Thumbnail")
}
