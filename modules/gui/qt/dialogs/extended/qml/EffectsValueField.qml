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

import VLC.Style
import VLC.Widgets as Widgets

// A text box of the player settings panel. Given a numeric value it shows it
// through `format` and reports typed numbers through edited().
Widgets.TextFieldExt {
    id: root

    property real value: 0
    property var format: null
    property bool numeric: true

    signal edited(real value)

    readonly property EffectsColors colors: EffectsColors { }

    implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

    topPadding: 0
    bottomPadding: 0

    selectByMouse: true
    font.pixelSize: VLCStyle.fontSize_normal

    function _show() {
        if (numeric)
            text = format ? format(value) : String(value)
    }

    onValueChanged: if (!activeFocus) _show()
    Component.onCompleted: _show()

    onActiveFocusChanged: {
        if (activeFocus)
            selectAll()
        else
            _show()
    }

    onEditingFinished: {
        if (!numeric)
            return
        const typed = parseFloat(text.replace(",", "."))
        if (isFinite(typed))
            root.edited(typed)
        _show()
    }
}
