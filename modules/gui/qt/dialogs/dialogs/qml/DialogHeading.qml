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

ColumnLayout {
    id: root

    property alias title: titleLabel.text
    property alias description: descriptionLabel.text

    spacing: VLCStyle.dp(5, VLCStyle.scale)

    Widgets.LabelExt {
        id: titleLabel

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)

        verticalAlignment: Text.AlignVCenter
        font.pixelSize: VLCStyle.fontSize_large
        color: VLCStyle.palette.fg2
        textFormat: Text.PlainText
    }

    Widgets.LabelExt {
        id: descriptionLabel

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(25, VLCStyle.scale)

        visible: text.length > 0
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        font.pixelSize: VLCStyle.fontSize_normal
        color: VLCStyle.palette.fgA3
        textFormat: Text.PlainText
    }
}
