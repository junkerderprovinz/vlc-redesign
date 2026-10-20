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
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style

T.MenuItem {
    id: control

    // Properties

    property string iconTxt: ""

    // shown on the right, such as a keyboard shortcut
    property string hint: ""

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: VLCStyle.margin_xxxsmall
    bottomPadding: VLCStyle.margin_xxxsmall
    leftPadding: VLCStyle.dp(14, VLCStyle.scale)
    rightPadding: VLCStyle.dp(14, VLCStyle.scale)

    spacing: VLCStyle.dp(10, VLCStyle.scale)

    font.pixelSize: VLCStyle.fontSize_large

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: control.menu?.colorContext?.palette ?? VLCStyle.palette
        colorSet: ColorContext.ComboBox

        enabled: control.enabled
        focused: control.visualFocus
        hovered: control.highlighted
        pressed: control.down
    }

    background: Rectangle {
        implicitWidth: VLCStyle.dp(257, VLCStyle.scale)
        implicitHeight: VLCStyle.heightBar_medium

        radius: VLCStyle.dp(6, VLCStyle.scale)

        color: (control.highlighted || control.down || (control.subMenu?.visible ?? false))
               ? theme.bg.highlight : "transparent"

        border.width: control.visualFocus ? VLCStyle.focus_border : 0
        border.color: theme.visualFocus
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Widgets.IconLabel {
            visible: text.length > 0

            text: control.iconTxt
            color: theme.fg.primary

            font.pixelSize: VLCStyle.icon_normal

            Layout.preferredWidth: VLCStyle.icon_normal
        }

        T.Label {
            text: control.text
            color: theme.fg.primary
            font: control.font

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            //item text is already exposed
            Accessible.ignored: true

            Layout.fillWidth: true
        }

        T.Label {
            visible: text.length > 0

            text: control.hint
            color: theme.fg.secondary
            font: control.font

            verticalAlignment: Text.AlignVCenter

            Accessible.ignored: true
        }

        Widgets.IconLabel {
            visible: control.checkable && control.checked

            text: VLCIcons.check
            color: theme.accent

            font.pixelSize: VLCStyle.icon_normal

            Layout.preferredWidth: VLCStyle.icon_normal
        }

        Widgets.IconLabel {
            visible: !!control.subMenu

            text: VLCIcons.ic_fluent_chevron_right_24
            color: theme.fg.secondary

            font.pixelSize: VLCStyle.icon_normal

            Layout.preferredWidth: VLCStyle.icon_normal
        }
    }

    arrow: null
    indicator: null
}
