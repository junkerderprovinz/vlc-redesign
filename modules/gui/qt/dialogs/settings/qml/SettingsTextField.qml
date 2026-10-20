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

import VLC.Widgets as Widgets
import VLC.Dialogs

// A text field that shows `value` and reports an edit once it is finished,
// with an optional unit after the text.
Widgets.TextFieldExt {
    id: root

    readonly property var t: SettingsTheme

    property string value
    property string unit
    property bool compact: false

    signal committed(string text)

    implicitWidth: t.controlWidth
    implicitHeight: compact ? t.dp(32) : t.dp(36)

    rightPadding: unitLabel.visible ? unitLabel.width + t.dp(18) : t.dp(18)

    font.pixelSize: t.fontNormal
    selectByMouse: true

    text: value

    onEditingFinished: {
        if (text !== value)
            committed(text)
    }

    onValueChanged: {
        if (!activeFocus)
            text = value
    }

    onActiveFocusChanged: {
        if (!activeFocus)
            text = value
    }

    Keys.onEscapePressed: (event) => {
        if (text !== value) {
            text = value
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    Text {
        id: unitLabel

        x: Math.min(root.leftPadding + root.contentWidth + t.dp(4), root.width - width - t.dp(14))
        anchors.verticalCenter: parent.verticalCenter
        visible: root.unit.length > 0 && root.text.length > 0
        text: root.unit
        color: t.fgA3
        font.pixelSize: t.fontNormal
    }
}
