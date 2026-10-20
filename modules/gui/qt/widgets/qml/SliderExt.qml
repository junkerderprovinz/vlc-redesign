/*****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
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

import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

T.Slider {
    id: control

    // helper to set colors based on given particular theme
    readonly property ColorContext colorContext: ColorContext {
        id: theme

        colorSet: ColorContext.Slider

        enabled: control.enabled
        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.pressed
    }

    // colors based on different parts and states
    property color color: (control.hovered || control.pressed || control.visualFocus) ? theme.fg.primary
                                                                                     : theme.fg.secondary
    property color bgColor: theme.bg.primary
    property color fillColor: theme.bg.secondary
    property color tickColor: theme.indicator

    property real handleWidth: VLCStyle.margin_xsmall

    property real radius: VLCStyle.dp(6, VLCStyle.scale)

    // the fill grows from this value to the current value
    property real fillOrigin: from

    // number of equal steps marked on the track, no marks below 2
    property int tickCount: 0

    // when set the tooltip will follow the mouse when control is hoverred
    // else tooltip will always be shown at current value.
    property bool toolTipFollowsMouse: false

    // toolTipTextProvider -> function(value)
    // arg "value" is between from and to, this is "value"
    // at which pointing tool tip is currently shown
    //
    // returns the text for the given value
    property var toolTipTextProvider: function (value) {
        return value
    }

    readonly property real _tooltipX: {
        if (toolTipFollowsMouse && hoverHandler.hovered)
            return  hoverHandler.point.position.x

        return (handle.x + handle.width / 2) // handle center
    }

    readonly property real _trackInset: VLCStyle.margin_xxxsmall

    readonly property real _originPosition: {
        const p = (to === from) ? 0 : Helpers.clamp((fillOrigin - from) / (to - from), 0, 1)
        return (horizontal && !mirrored) ? p : 1 - p
    }

    // find position under given x, can be used with Slider::valueAt()
    // x is coordinate in this control's coordinate space
    function positionAt(x) {
        // taken from qt sources QQuickSlider.cpp
        // TODO: support vertical slider
        const hw = control.handle.width
        const offset = control.leftPadding + hw / 2
        const extend = control.availableWidth - hw
        return (x - offset) / extend
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitHandleWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitHandleHeight + topPadding + bottomPadding)

    leftPadding: horizontal ? _trackInset : 0
    rightPadding: horizontal ? _trackInset : 0
    topPadding: horizontal ? 0 : _trackInset
    bottomPadding: horizontal ? 0 : _trackInset

    handle: Rectangle {
        x: control.leftPadding + (control.horizontal
                                  ? control.visualPosition * (control.availableWidth - width)
                                  : (control.availableWidth - width) / 2)

        y: control.topPadding + (control.horizontal
                                 ? (control.availableHeight - height) / 2
                                 : control.visualPosition * (control.availableHeight - height))

        implicitWidth: control.horizontal ? control.handleWidth : VLCStyle.margin_large
        implicitHeight: control.horizontal ? VLCStyle.margin_large : control.handleWidth

        radius: VLCStyle.margin_xxsmall

        color: control.color

        border.width: control.visualFocus ? VLCStyle.focus_border : 0
        border.color: theme.visualFocus
    }

    background: Item {
        implicitWidth: control.horizontal ? VLCStyle.heightBar_xlarge : VLCStyle.margin_large
        implicitHeight: control.horizontal ? VLCStyle.margin_large : VLCStyle.heightBar_xlarge

        Rectangle {
            id: track

            readonly property real _thickness: VLCStyle.margin_normal

            x: control.horizontal ? 0 : (parent.width - width) / 2
            y: control.horizontal ? (parent.height - height) / 2 : 0

            width: control.horizontal ? parent.width : _thickness
            height: control.horizontal ? _thickness : parent.height

            radius: control.radius

            color: control.bgColor

            // like the handle, the fill travels inside the inset of the track
            Rectangle {
                readonly property real _start: Math.min(control.visualPosition, control._originPosition)
                readonly property real _end: Math.max(control.visualPosition, control._originPosition)
                readonly property real _travel: (control.horizontal ? track.width : track.height)
                                                - control._trackInset * 2 - control.handleWidth

                x: control.horizontal ? control._trackInset + _start * _travel : control._trackInset
                y: control.horizontal ? control._trackInset : control._trackInset + _start * _travel

                width: control.horizontal ? (_end - _start) * _travel + control.handleWidth
                                          : track.width - control._trackInset * 2
                height: control.horizontal ? track.height - control._trackInset * 2
                                           : (_end - _start) * _travel + control.handleWidth

                radius: VLCStyle.margin_xxsmall

                color: control.fillColor
            }

            Repeater {
                model: control.tickCount > 1 ? control.tickCount - 1 : 0

                delegate: Rectangle {
                    required property int index

                    readonly property real _travel: (control.horizontal ? track.width : track.height)
                                                    - control._trackInset * 2 - control.handleWidth
                    readonly property real _center: control._trackInset + control.handleWidth / 2
                                                    + (index + 1) / control.tickCount * _travel

                    x: control.horizontal ? _center - width / 2 : (track.width - width) / 2
                    y: control.horizontal ? (track.height - height) / 2 : _center - height / 2

                    width: control.horizontal ? VLCStyle.margin_xxxsmall : VLCStyle.dp(6, VLCStyle.scale)
                    height: control.horizontal ? VLCStyle.dp(6, VLCStyle.scale) : VLCStyle.margin_xxxsmall

                    color: control.tickColor
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        enabled: true

        target: background
    }

    Widgets.PointingToolTipAttached.pos: Qt.point(control._tooltipX, control.handle.height / 2)
    Widgets.PointingToolTipAttached.visible: (hoverHandler.hovered || control.visualFocus || control.pressed)
    Widgets.PointingToolTipAttached.text: {
        if (!Widgets.PointingToolTipAttached.instance?.visible)
            return ""

        // position is only measured till half of handle width
        // pos.x may go beyond the position at the edges
        const p = Helpers.clamp(control.positionAt(Widgets.PointingToolTipAttached.instance.pos.x), 0.0, 1.0)
        const v = control.valueAt(p)
        return control.toolTipTextProvider(v)
    }

}
