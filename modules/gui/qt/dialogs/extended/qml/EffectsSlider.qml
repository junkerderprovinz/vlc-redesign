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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.Style
import VLC.Widgets as Widgets

// A labelled slider of the player settings panel: the label and the value
// above, an optional typed value box, and optional labels under the track.
ColumnLayout {
    id: root

    property string label
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    // the value the fill grows from, the left end by default
    property real origin: from
    // number of equal steps marked on the track
    property int ticks: 0
    // value restored on double click
    property real resetValue: NaN

    // formats a value for display; with no function only the label shows
    property var format: null
    // shows the value in an editable box instead of a plain text
    property bool editable: false
    property var scaleLabels: []

    readonly property alias pressed: slider.pressed

    signal moved(real value)

    Layout.fillWidth: true
    spacing: VLCStyle.dp(5, VLCStyle.scale)

    readonly property EffectsColors colors: EffectsColors { }

    function _commit(v) {
        root.moved(Math.min(root.to, Math.max(root.from, v)))
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.editable ? VLCStyle.dp(56, VLCStyle.scale)
                                              : VLCStyle.dp(37, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)

        T.Label {
            Layout.fillWidth: true

            text: root.label
            color: root.colors.label
            font.pixelSize: VLCStyle.fontSize_normal
            elide: Text.ElideRight
        }

        T.Label {
            visible: !root.editable && !!root.format

            text: root.format ? root.format(slider.pressed ? slider.value : root.value) : ""
            color: root.colors.label
            font.pixelSize: VLCStyle.fontSize_normal
        }

        EffectsValueField {
            visible: root.editable

            value: slider.pressed ? slider.value : root.value
            format: root.format
            Accessible.name: root.label

            onEdited: (v) => root._commit(v)
        }
    }

    Widgets.SliderExt {
        id: slider

        Layout.fillWidth: true

        from: root.from
        to: root.to
        stepSize: root.stepSize
        snapMode: T.Slider.SnapAlways
        fillOrigin: root.origin
        tickCount: root.ticks

        Accessible.name: root.label

        toolTipTextProvider: (v) => root.format ? root.format(v) : v.toFixed(2)

        Binding on value {
            when: !slider.pressed
            value: root.value
            restoreMode: Binding.RestoreNone
        }

        onMoved: root._commit(slider.value)

        TapHandler {
            onDoubleTapped: {
                if (!isNaN(root.resetValue))
                    root._commit(root.resetValue)
            }
        }
    }

    Item {
        visible: root.scaleLabels.length > 0

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(15, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(4, VLCStyle.scale)

        Repeater {
            model: root.scaleLabels

            delegate: T.Label {
                required property string modelData
                required property int index

                readonly property real _at: index / Math.max(1, root.scaleLabels.length - 1)

                x: {
                    if (index === 0)
                        return 0
                    if (index === root.scaleLabels.length - 1)
                        return parent.width - width
                    return VLCStyle.dp(6, VLCStyle.scale) + _at * (parent.width - VLCStyle.dp(12, VLCStyle.scale)) - width / 2
                }

                text: modelData
                color: root.colors.label
                font.pixelSize: VLCStyle.fontSize_small
            }
        }
    }
}
