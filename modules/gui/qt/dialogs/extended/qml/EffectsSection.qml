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

import VLC.Style
import VLC.Widgets as Widgets

// A titled block of the player settings panel, separated from the block above
ColumnLayout {
    id: root

    property string title
    property bool separator: true

    default property alias content: body.data
    property alias bodySpacing: body.spacing
    property real bodyTopMargin: VLCStyle.dp(10, VLCStyle.scale)

    readonly property EffectsColors colors: EffectsColors { }

    Layout.fillWidth: true
    spacing: 0

    Rectangle {
        visible: root.separator

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.border

        color: root.colors.divider
    }

    Widgets.LabelExt {
        visible: root.title !== ""

        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)

        text: root.title
        color: root.colors.heading
        font.pixelSize: VLCStyle.fontSize_large
        font.weight: Font.Medium
        Accessible.role: Accessible.Heading
    }

    ColumnLayout {
        id: body

        Layout.fillWidth: true
        Layout.topMargin: root.bodyTopMargin
        Layout.bottomMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: VLCStyle.dp(5, VLCStyle.scale)
    }
}
