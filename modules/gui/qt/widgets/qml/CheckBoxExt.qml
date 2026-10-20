/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
 * Copyright (C) 2017 The Qt Company Ltd.
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

import VLC.MainInterface
import VLC.Style
import VLC.Widgets

// Based on Qt Quick Basic Style, drawn as the ON/OFF toggle with the text on its left.
T.CheckBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_xxsmall
    spacing: VLCStyle.dp(10, VLCStyle.scale)

    font.pixelSize: VLCStyle.fontSize_large

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.ButtonStandard

        focused: control.visualFocus
        hovered: control.hovered
        enabled: control.enabled
        pressed: control.down
    }

    indicator: ToggleIndicator {
        x: control.text ? (control.mirrored ? control.leftPadding : control.width - width - control.rightPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2

        enabled: control.enabled

        checked: (control.checkState !== Qt.Unchecked)
        position: (control.checkState === Qt.PartiallyChecked) ? 0.5 : (checked ? 1.0 : 0.0)

        visualFocus: control.visualFocus
    }

    contentItem: ListLabel {
        leftPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0

        verticalAlignment: Text.AlignVCenter

        text: control.text
        font: control.font
        color: theme.fg.primary
    }
}
