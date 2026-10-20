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
import QtQuick.Layouts

import VLC.Widgets as Widgets
import VLC.Style

// The compact dropdown of a dialog toolbar, model entries are { text, value }.
Widgets.FormComboBox {
    id: control

    selectedIndex: 0
    onActivated: (index) => selectedIndex = index

    Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
    Layout.fillHeight: true

    textRole: "text"
    valueRole: "value"

    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
    rightPadding: VLCStyle.dp(8, VLCStyle.scale)
    font.pixelSize: VLCStyle.fontSize_large

    color: VLCStyle.palette.fgA1

    indicator: Widgets.IconLabel {
        x: control.width - width - control.rightPadding
        y: (control.height - height) / 2

        text: VLCIcons.chevron_down
        color: VLCStyle.palette.fgA2
        font.pixelSize: VLCStyle.icon_normal
        rotation: control.popup.visible ? 180 : 0
    }

    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: (control.hovered || control.visualFocus) ? (VLCStyle.palette.isDark ? VLCStyle.palette.bgA4 : VLCStyle.palette.bgA1)
                                                       : (VLCStyle.palette.isDark ? VLCStyle.palette.bgA5 : VLCStyle.palette.bgA2)
        border.color: VLCStyle.palette.accentDim
        border.width: control.visualFocus ? VLCStyle.focus_border : 0
    }
}
