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
import QtQuick.Window

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style

// A popup menu drawn in QML, use MenuItemExt and MenuSeparatorExt as its items.
T.Menu {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    margins: VLCStyle.margin_xsmall
    padding: VLCStyle.margin_xxsmall
    overlap: VLCStyle.margin_xxsmall

    font.pixelSize: VLCStyle.fontSize_large

    delegate: MenuItemExt { }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.ComboBox
    }

    contentItem: ListView {
        implicitWidth: {
            let width = 0
            for (let i = 0; i < count; ++i) {
                const item = control.itemAt(i)
                if (item)
                    width = Math.max(width, item.implicitWidth)
            }
            return width
        }
        implicitHeight: contentHeight

        model: control.contentModel

        interactive: Window.window ? contentHeight + control.topPadding + control.bottomPadding > Window.window.height
                                   : false
        clip: true
        currentIndex: control.currentIndex

        T.ScrollBar.vertical: Widgets.ScrollBarExt {
            colorContext.palette: theme.palette
        }
    }

    background: Rectangle {
        implicitWidth: VLCStyle.dp(265, VLCStyle.scale)

        radius: VLCStyle.dp(10, VLCStyle.scale)

        color: theme.bg.neutral

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.margin_xsmall
            blurRadius: VLCStyle.dp(8, VLCStyle.scale)

            color: theme.shadow
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: VLCStyle.duration_short }
    }
}
