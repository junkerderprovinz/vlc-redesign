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

// One option of a SegmentedControl.
T.AbstractButton {
    id: control

    // Properties

    property int horizontalAlignment: Text.AlignHCenter

    // shown after the text, such as the value field of an option
    property alias trailing: trailingLoader.sourceComponent
    readonly property alias trailingItem: trailingLoader.item

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    checkable: true
    autoExclusive: true

    padding: VLCStyle.margin_xxxsmall
    leftPadding: VLCStyle.margin_small
    rightPadding: trailingLoader.active ? VLCStyle.margin_xxxsmall : VLCStyle.margin_small

    spacing: VLCStyle.dp(10, VLCStyle.scale)

    font.pixelSize: VLCStyle.fontSize_large

    // Keys

    Keys.priority: Keys.AfterItem

    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    // Accessible

    Accessible.role: Accessible.RadioButton
    Accessible.onPressAction: control.clicked()

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Switch

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    background: Widgets.AnimatedBackground {
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

        enabled: theme.initialized

        animationDuration: VLCStyle.duration_short

        radius: VLCStyle.button_radius

        color: control.checked ? theme.bg.secondary : theme.bg.highlight
        border.color: control.visualFocus ? theme.visualFocus : Qt.alpha(theme.visualFocus, 0.0)
    }

    contentItem: RowLayout {
        spacing: control.spacing

        T.Label {
            text: control.text

            color: control.checked ? theme.fg.secondary : theme.fg.primary

            font: control.font

            elide: Text.ElideRight
            horizontalAlignment: control.horizontalAlignment
            verticalAlignment: Text.AlignVCenter

            //button text is already exposed
            Accessible.ignored: true

            Layout.fillWidth: !trailingLoader.active
            Layout.fillHeight: true
        }

        Loader {
            id: trailingLoader

            active: !!sourceComponent

            Layout.fillWidth: active
            Layout.fillHeight: active
        }
    }
}
