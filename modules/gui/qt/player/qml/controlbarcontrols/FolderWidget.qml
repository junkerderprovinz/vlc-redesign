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
import QtQuick.Templates as T


import VLC.Style
import VLC.Player


T.Label {
    id: folderLabel

    property bool paintOnly: false

    readonly property string folderName: {
        const path = Player.url.toString().replace(/[?#].*$/, "")
        if (!path.startsWith("file:"))
            return ""
        const parts = path.split("/").filter((part) => part.length > 0)
        if (parts.length < 3)
            return ""
        try {
            return decodeURIComponent(parts[parts.length - 2])
        } catch (e) {
            return parts[parts.length - 2]
        }
    }

    implicitWidth: Math.min(implicitContentWidth + leftPadding + rightPadding, VLCStyle.dp(240, VLCStyle.scale))

    padding: VLCStyle.margin_xxxsmall
    leftPadding: VLCStyle.dp(6, VLCStyle.scale)
    rightPadding: leftPadding

    text: (paintOnly && !folderName) ? qsTr("Folder Name") : folderName

    color: theme.fg.secondary
    font.pixelSize: VLCStyle.fontSize_large
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.ToolButton
    }
}
