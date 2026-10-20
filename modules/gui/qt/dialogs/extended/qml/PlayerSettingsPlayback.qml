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
import VLC.Util
import VLC.Widgets as Widgets

ColumnLayout {
    id: root

    spacing: 0

    readonly property EffectsColors colors: EffectsColors { }

    // icons of the visualizations, by the names the audio output gives them
    readonly property var _visualizerImages: ({
        [qsTr("Spectrometer")]: "spectometer-duo",
        [qsTr("Scope")]: "scope-duo",
        [qsTr("Spectrum")]: "spectrum-duo",
        [qsTr("VU meter")]: "waveform-duo"
    })

    Widgets.FormSection {
        separator: false
        bodySpacing: 0

        Widgets.FormRow {
            label: qsTr("Show Statistics")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            Widgets.FormSwitch {
                value: DialogsProvider.mediaStatsVisible
                onSwitched: (on) => DialogsProvider.mediaStatsVisible = on
            }
        }

        Widgets.FormRow {
            label: qsTr("Reverse")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)
            enabled: Player.rewindable

            Widgets.FormSwitch {
                value: Player.rate < 0
                onSwitched: Player.reverse()
            }
        }

        Widgets.FormRow {
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            label: qsTr("Sleep Timer")

            Widgets.FormComboBox {
                id: sleepTimer

                readonly property var _minutes: [0, 15, 30, 45, 60, 120]

                model: [qsTr("Off"), qsTr("15 minutes"), qsTr("30 minutes"), qsTr("45 minutes"),
                        qsTr("1 hour"), qsTr("2 hours")]
                selectedIndex: Math.max(0, _minutes.indexOf(EffectsController.sleepTimer))
                onActivated: (index) => EffectsController.sleepTimer = _minutes[index]
                Accessible.name: qsTr("Sleep Timer")
            }
        }

        Widgets.FormRow {
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            label: qsTr("Audio Visualizer")

            Widgets.FormComboBox {
                model: Player.audioVisualization
                textRole: "display"
                checkable: true
                imageForText: (text) => {
                    const slug = root._visualizerImages[text]
                    if (!slug)
                        return ""
                    return SVGColorImage.colorize("qrc:///icons/ui/" + slug + ".svg")
                                        .color1(root.colors.label).color2(root.colors.accent).uri()
                }
                Accessible.name: qsTr("Audio Visualizer")
            }
        }

        EffectsSlider {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)

            label: qsTr("Speed")
            editable: true
            enabled: Player.ratechangable
            from: 0.25
            to: 2
            stepSize: 0.05
            ticks: 7
            resetValue: 1
            value: Math.abs(Player.rate)
            format: (v) => Number(v.toFixed(2)) + "x"
            scaleLabels: ["0.25", "0.5", "0.75", "1", "1.25", "1.5", "1.75", "2"]

            onMoved: (v) => Player.rate = (Player.rate < 0) ? -v : v
        }
    }
}
