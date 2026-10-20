/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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
import VLC.Util

T.ItemDelegate {
    id: control

    // Properties

    property string iconTxt: ""

    property bool showText: true

    // Sub entries have no icon, they line up with the label of their parent.
    property bool indented: false

    property real radius: VLCStyle.margin_xxsmall

    readonly property real iconWidth: VLCStyle.dp(30, VLCStyle.scale)

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0
    leftPadding: (showText && indented) ? iconWidth + spacing : 0

    spacing: VLCStyle.margin_xsmall

    // Accessible

    Accessible.onPressAction: control.clicked()
    AccessibleCompat.id: {
        if (model.depth !== 0 || !model.uri || model.uri.length === 0) return "";
        const navBarIds = {
            "home": "homeNavBar",
            "video": "videoNavBar",
            "music": "musicNavBar",
            "network": "browseNavBar",
            "playlists": "playlistsNavBar",
            "recent": "recentNavBar",
            "discover": "discoverNavBar"
        }
        const id = navBarIds[model.uri[0]]
        if (id !== undefined)
            return id
        else
            return ""
    }

    // Tooltip

    T.ToolTip.visible: (showText === false && T.ToolTip.text && (hovered || visualFocus))

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    T.ToolTip.text: text

    // Childs

    ColorContext {
        id: theme
        colorSet: ColorContext.TabButton

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    background: Widgets.AnimatedBackground {
        enabled: theme.initialized
        color: theme.bg.primary
        border.color: visualFocus ? theme.visualFocus : "transparent"

        radius: control.radius
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Widgets.IconLabel {
            id: iconLabel

            Layout.preferredWidth: control.iconWidth
            Layout.fillHeight: true

            visible: text.length > 0 && !control.indented

            text: control.iconTxt

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            color: (control.highlighted || control.checked) ? theme.accent : theme.fg.primary

            font.pixelSize: VLCStyle.icon_normal
        }

        T.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            text: control.text

            verticalAlignment: Text.AlignVCenter

            color: control.checked ? theme.fg.secondary : theme.fg.primary

            elide: Text.ElideRight

            visible: control.showText

            font.pixelSize: VLCStyle.fontSize_large

            //button text is already exposed
            Accessible.ignored: true

            Behavior on color {
                enabled: theme.initialized

                ColorAnimation {
                    duration: VLCStyle.duration_short
                }
            }
        }
    }
}
