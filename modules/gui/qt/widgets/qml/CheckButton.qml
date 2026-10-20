/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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

T.Switch {
    id: root

    // Style

    property int animationDuration: VLCStyle.duration_short

    property color color: checked ? colorContext.bg.secondary : colorContext.bg.highlight

    property color colorHandle: checked ? colorContext.accent : colorContext.indicator

    property color colorBorder: "transparent"

    // Settings

    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    T.ToolTip.visible: (T.ToolTip.text && (hovered || visualFocus))

    T.ToolTip.text: text

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    // Keys

    Keys.priority: Keys.AfterItem

    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    // Accessible

    Accessible.onPressAction: root.toggle()
    Accessible.onToggleAction: root.toggle()

    // Children

    readonly property ColorContext colorContext: indicator.colorContext

    indicator: ToggleIndicator {
        id: indicator

        anchors.fill: parent

        enabled: root.enabled

        checked: root.checked
        position: root.visualPosition

        animated: !root.down
        animationDuration: root.animationDuration

        visualFocus: root.visualFocus

        plateColor: root.color
        knobColor: root.colorHandle

        border.color: root.visualFocus ? colorContext.visualFocus : root.colorBorder
        border.width: (root.visualFocus || root.colorBorder.a > 0) ? VLCStyle.focus_border : 0
    }
}
