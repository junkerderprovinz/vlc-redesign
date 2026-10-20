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

import VLC.Dialogs
import VLC.Player
import VLC.Style

// The subtitle tracks are picked from the tracks popup of the control bar,
// this tab holds their timing and look.
ColumnLayout {
    id: root

    property var expanded: ({})

    spacing: 0

    function opt(name) {
        EffectsController.revision
        return EffectsController.option(name)
    }

    // text scales, in percent, of the font size steps
    readonly property var _textScales: [50, 65, 80, 100, 125, 150]
    readonly property var _outlines: EffectsController.optionChoices("freetype-outline-thickness")

    function _nearest(list, value) {
        let best = 0
        for (let i = 1; i < list.length; i++) {
            if (Math.abs(list[i] - value) < Math.abs(list[best] - value))
                best = i
        }
        return best
    }

    EffectsSection {
        title: qsTr("Defaults")
        separator: false
        bodySpacing: 0

        EffectsRow {
            Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
            label: qsTr("Subtitle Language")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsValueField {
                numeric: false
                text: root.opt("sub-language")
                Accessible.name: qsTr("Subtitle Language")
                onEditingFinished: EffectsController.setOption("sub-language", text.trim())
            }
        }
    }

    EffectsSection {
        title: qsTr("Synchronization")

        EffectsSlider {
            label: qsTr("Subtitle Track Delay")
            editable: true
            from: -10; to: 10; stepSize: 0.05; origin: 0; resetValue: 0
            value: Player.subtitleDelayMS / 1000
            format: (v) => v.toFixed(3) + " s"
            scaleLabels: ["-10 s", "0 s", "+10 s"]

            onMoved: (v) => Player.subtitleDelayMS = Math.round(v * 1000)
        }

        EffectsSlider {
            label: qsTr("Subtitle Speed")
            editable: true
            from: 1; to: 100; stepSize: 0.1; resetValue: 1
            value: Player.subtitleFPS
            format: (v) => v.toFixed(3) + " " + qsTr("fps")

            onMoved: (v) => Player.subtitleFPS = v
        }

        EffectsSlider {
            label: qsTr("Subtitle Duration Factor")
            editable: true
            enabled: Player.hasVideoOutput
            from: 0; to: 20; stepSize: 0.1; resetValue: 0
            value: (EffectsController.revision, EffectsController.subtitleDurationFactor())
            format: (v) => v.toFixed(3)

            onMoved: (v) => EffectsController.setSubtitleDurationFactor(v)
        }
    }

    EffectsSection {
        title: qsTr("Appearance")
        bodySpacing: 0

        EffectsRow {
            label: qsTr("Embedded Sub Format")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsSwitch {
                value: !!root.opt("subsdec-formatting")
                onSwitched: (on) => EffectsController.setOption("subsdec-formatting", on)
                Accessible.name: qsTr("Embedded Sub Format")
            }
        }

        EffectsRow {
            label: qsTr("Subtitle Font")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsValueField {
                numeric: false
                text: root.opt("freetype-font")
                Accessible.name: qsTr("Subtitle Font")
                onEditingFinished: EffectsController.setOption("freetype-font", text.trim())
            }
        }

        EffectsRow {
            label: qsTr("Text Color")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsColorField {
                implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                rgb: root.opt("freetype-color")
                Accessible.name: qsTr("Text Color")
                onPicked: (rgb) => EffectsController.setOption("freetype-color", rgb)
            }
        }

        EffectsRow {
            label: qsTr("Outline Color")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsColorField {
                implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                rgb: root.opt("freetype-outline-color")
                Accessible.name: qsTr("Outline Color")
                onPicked: (rgb) => EffectsController.setOption("freetype-outline-color", rgb)
            }
        }

        EffectsRow {
            label: qsTr("Subtitle Offset")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            EffectsValueField {
                value: root.opt("sub-margin")
                format: (v) => Math.round(v) + "px"
                Accessible.name: qsTr("Subtitle Offset")
                onEdited: (v) => EffectsController.setOption("sub-margin", Math.round(v))
            }
        }

        EffectsSlider {
            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)

            readonly property var _names: [qsTr("Smallest"), qsTr("Smaller"), qsTr("Small"),
                                           qsTr("Auto"), qsTr("Large"), qsTr("Larger")]

            label: qsTr("Font Size")
            from: 0; to: 5; stepSize: 1; ticks: 5; resetValue: 3
            value: root._nearest(root._textScales, EffectsController.subtitleTextScale)
            format: (v) => _names[Math.round(v)]

            onMoved: (v) => EffectsController.subtitleTextScale = root._textScales[Math.round(v)]
        }

        EffectsSlider {
            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)

            visible: root._outlines.length > 1
            label: qsTr("Outline Thickness")
            from: 0; to: Math.max(1, root._outlines.length - 1); stepSize: 1
            ticks: Math.max(1, root._outlines.length - 1)
            value: Math.max(0, root._outlines.findIndex((c) => c.value === root.opt("freetype-outline-thickness")))
            format: (v) => root._outlines[Math.round(v)]?.text ?? ""

            onMoved: (v) => EffectsController.setOption("freetype-outline-thickness", root._outlines[Math.round(v)].value)
        }

        EffectsSlider {
            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)

            label: qsTr("Background Opacity")
            from: 0; to: 100; stepSize: 1; ticks: 4; resetValue: 0
            value: Math.round(root.opt("freetype-background-opacity") * 100 / 255)
            format: (v) => Math.round(v) + " %"

            onMoved: (v) => EffectsController.setOption("freetype-background-opacity", Math.round(v * 255 / 100))
        }
    }
}
