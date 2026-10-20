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

Widgets.DialogButton {
    id: root

    readonly property var t: SettingsTheme

    property bool danger: false
    // highlighted while a second click is awaited to confirm the action
    property bool armed: false

    implicitHeight: t.dp(32)
    leftPadding: t.dp(16)
    rightPadding: t.dp(16)

    font.pixelSize: t.fontNormal

    color: {
        if (danger)
            return armed ? "white" : t.danger
        return armed ? t.accent : colorContext.fg.secondary
    }
    backgroundColor: {
        if (danger)
            return armed ? t.danger : t.mix(t.danger, t.bgB2, hovered ? 0.2 : 0.1)
        return armed ? t.accentBgBright : colorContext.bg.secondary
    }
}
