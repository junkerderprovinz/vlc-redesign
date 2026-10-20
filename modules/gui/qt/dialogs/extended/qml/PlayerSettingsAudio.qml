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

    // expanded cards, kept by the panel across tab changes
    property var expanded: ({})

    spacing: 0

    function opt(name) {
        EffectsController.revision
        return EffectsController.option(name)
    }

    readonly property EffectsColors colors: EffectsColors { }

    ConfigOption { id: vlcFrequencies; name: "equalizer-vlcfreqs" }

    // icon files of the equalizer presets
    readonly property var _equalizerIcons: ({
        "classical": "eq-classical", "club": "eq-club", "dance": "eq-dance",
        "fullbass": "eq-full-bass", "fullbasstreble": "eq-full-bass-and-treble",
        "fulltreble": "eq-full-treble", "headphones": "eq-headphones", "largehall": "eq-large-hall",
        "live": "eq-live", "party": "eq-party", "pop": "eq-pop", "reggae": "eq-reggae",
        "rock": "eq-rock", "ska": "eq-ska", "soft": "eq-soft", "softrock": "eq-soft-rock",
        "techno": "eq-techno"
    })

    function _equalizerImage(id) {
        const slug = _equalizerIcons[id]
        if (!slug)
            return ""
        return SVGColorImage.colorize("qrc:///icons/ui/" + slug + ".svg")
                            .color1(colors.label).accent(colors.accent).uri()
    }

    function on(module) {
        EffectsController.revision
        return EffectsController.isFilterEnabled(module)
    }

    component FilterHead : Widgets.FormRow {
        id: filterHead

        // the filter switched on and off from the head, if any
        property string module

        minimumHeight: VLCStyle.dp(37, VLCStyle.scale)

        Widgets.FormSwitch {
            visible: filterHead.module !== ""
            value: EffectsController.revision, (filterHead.module !== "" && EffectsController.isFilterEnabled(filterHead.module))
            onSwitched: (on) => EffectsController.setFilterEnabled(filterHead.module, on)
            Accessible.name: filterHead.label
        }
    }

    // A slider bound to one option of an audio filter
    component FilterSlider : EffectsSlider {
        id: filterSlider

        property string option
        // the option is shown multiplied by this factor
        property real factor: 1

        Layout.fillWidth: true
        value: (EffectsController.revision, EffectsController.option(option) * factor)
        resetValue: EffectsController.defaultOption(option) * factor
        onMoved: (v) => EffectsController.setOption(option, v / factor)
    }

    readonly property var _decibels: (v) => v.toFixed(1) + " " + qsTr("dB")

    Widgets.FormSection {
        title: qsTr("Defaults")
        separator: false
        bodySpacing: 0

        Widgets.FormRow {
            label: qsTr("Audio Track")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            Widgets.FormComboBox {
                implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                model: Player.audioTracks
                textRole: "display"
                checkable: true
                Accessible.name: qsTr("Audio Track")
            }
        }

        Widgets.FormRow {
            label: qsTr("Audio Language")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)

            Widgets.FormTextField {
                value: root.opt("audio-language")
                Accessible.name: qsTr("Audio Language")
                onCommitted: (text) => EffectsController.setOption("audio-language", text.trim())
            }
        }

        Widgets.FormRow {
            label: (EffectsController.revision, Player.audioMixMode.rowCount() > 0) ? qsTr("Mix Mode") : qsTr("Stereo Mode")
            minimumHeight: VLCStyle.dp(52, VLCStyle.scale)
        }

        Widgets.FormComboBox {
            Layout.fillWidth: true
            Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)

            model: (EffectsController.revision, Player.audioMixMode.rowCount() > 0) ? Player.audioMixMode : Player.audioStereoMode
            textRole: "display"
            checkable: true
            Accessible.name: qsTr("Stereo Mode")
        }
    }

    Widgets.FormSection {
        title: qsTr("Synchronization")

        EffectsSlider {
            Layout.fillWidth: true

            label: qsTr("Audio Track Delay")
            editable: true
            from: -10
            to: 10
            stepSize: 0.05
            origin: 0
            resetValue: 0
            value: Player.audioDelayMS / 1000
            format: (v) => v.toFixed(3) + " s"
            scaleLabels: ["-10 s", "0 s", "+10 s"]

            onMoved: (v) => Player.audioDelayMS = Math.round(v * 1000)
        }
    }

    Widgets.FormSection {
        title: qsTr("Filters")
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)

        FilterHead { label: qsTr("Equalizer") }

        Widgets.FormComboBox {
            // the flat preset has a single color glyph, the others two-tone images
            readonly property var _presets: [{ id: "", name: qsTr("None"), icon: "", image: "" }].concat(
                SettingsBridge.equalizerPresets.map((p) => ({
                    id: p.id,
                    name: p.name,
                    icon: p.id === "flat" ? VLCIcons.eq : "",
                    image: p.id === "flat" ? "" : root._equalizerImage(p.id)
                })))

            Layout.fillWidth: true

            model: _presets
            textRole: "name"
            iconRole: "icon"
            imageRole: "image"
            selectedIndex: {
                EffectsController.revision
                const current = EffectsController.equalizerPreset()
                return Math.max(0, _presets.findIndex((p) => p.id === current))
            }
            onActivated: (index) => EffectsController.setEqualizerPreset(_presets[index].id)
            Accessible.name: qsTr("Equalizer preset")
        }

        EffectsExpander {
            store: root.expanded
            key: "equalizer"

            FilterSlider {
                label: qsTr("Preamp")
                option: "equalizer-preamp"
                editable: true
                from: -20; to: 20; stepSize: 0.1
                format: root._decibels
            }

            Repeater {
                model: SettingsBridge.equalizerBandNames(!!vlcFrequencies.value)

                delegate: EffectsSlider {
                    Layout.fillWidth: true

                    label: modelData
                    editable: true
                    from: -20; to: 20; stepSize: 0.1; resetValue: 0
                    value: (EffectsController.revision, EffectsController.equalizerBands()[index] ?? 0)
                    format: root._decibels

                    onMoved: (v) => EffectsController.setEqualizerBand(index, v)
                }
            }
        }

        Widgets.FormRow {
            label: qsTr("2 Pass")

            Widgets.FormSwitch {
                value: !!root.opt("equalizer-2pass")
                onSwitched: (on) => EffectsController.setOption("equalizer-2pass", on)
                Accessible.name: qsTr("2 Pass")
            }
        }
    }

    Widgets.FormSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Compressor"); module: "compressor" }

        EffectsExpander {
            store: root.expanded
            key: "compressor"

            FilterSlider {
                label: qsTr("RMS / Peak"); option: "compressor-rms-peak"
                from: 0; to: 1; stepSize: 0.1
                format: (v) => v.toFixed(1)
            }
            FilterSlider {
                label: qsTr("Attack"); option: "compressor-attack"
                from: 1.5; to: 400; stepSize: 0.5
                format: (v) => v.toFixed(1) + " " + qsTr("ms")
            }
            FilterSlider {
                label: qsTr("Release"); option: "compressor-release"
                from: 2; to: 800; stepSize: 1
                format: (v) => v.toFixed(1) + " " + qsTr("ms")
            }
            FilterSlider {
                label: qsTr("Threshold"); option: "compressor-threshold"
                from: -30; to: 0; stepSize: 0.5
                format: root._decibels
            }
            FilterSlider {
                label: qsTr("Ratio"); option: "compressor-ratio"
                from: 1; to: 20; stepSize: 0.1
                format: (v) => v.toFixed(1) + " : 1"
            }
            FilterSlider {
                label: qsTr("Knee Radius"); option: "compressor-knee"
                from: 1; to: 10; stepSize: 0.1
                format: root._decibels
            }
            FilterSlider {
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                label: qsTr("Makeup Gain"); option: "compressor-makeup-gain"
                from: 0; to: 24; stepSize: 0.1
                format: root._decibels
            }
        }
    }

    Widgets.FormSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Spatializer"); module: "spatializer" }

        EffectsExpander {
            store: root.expanded
            key: "spatializer"

            FilterSlider {
                label: qsTr("Size"); option: "spatializer-roomsize"; factor: 10
                from: 0; to: 11; stepSize: 0.1; ticks: 11
                format: (v) => v.toFixed(1)
            }
            FilterSlider {
                label: qsTr("Width"); option: "spatializer-width"; factor: 10
                from: 0; to: 10; stepSize: 0.1; ticks: 10
                format: (v) => v.toFixed(1)
            }
            FilterSlider {
                label: qsTr("Wet"); option: "spatializer-wet"; factor: 10
                from: 0; to: 10; stepSize: 0.1; ticks: 10
                format: (v) => v.toFixed(1)
            }
            FilterSlider {
                label: qsTr("Dry"); option: "spatializer-dry"; factor: 10
                from: 0; to: 10; stepSize: 0.1; ticks: 10
                format: (v) => v.toFixed(1)
            }
            FilterSlider {
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                label: qsTr("Damp"); option: "spatializer-damp"; factor: 10
                from: 0; to: 10; stepSize: 0.1; ticks: 10
                format: (v) => v.toFixed(1)
            }
        }
    }

    Widgets.FormSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Stereo Widener"); module: "stereo_widen" }

        EffectsExpander {
            store: root.expanded
            key: "widener"

            FilterSlider {
                label: qsTr("Delay Time"); option: "stereowiden-delay"
                from: 1; to: 100; stepSize: 1
                format: (v) => v.toFixed(1) + " " + qsTr("ms")
            }
            FilterSlider {
                label: qsTr("Feedback Gain"); option: "stereowiden-feedback"
                from: 0; to: 0.9; stepSize: 0.1; ticks: 9
                format: (v) => v.toFixed(1) + " %"
            }
            FilterSlider {
                label: qsTr("Crossfeed"); option: "stereowiden-crossfeed"
                from: 0; to: 0.8; stepSize: 0.1; ticks: 8
                format: (v) => v.toFixed(1) + " %"
            }
            FilterSlider {
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                label: qsTr("Dry Mix"); option: "stereowiden-dry-mix"
                from: 0; to: 1; stepSize: 0.1; ticks: 10
                format: (v) => v.toFixed(1) + " %"
            }
        }
    }

    Widgets.FormSection {
        EffectsSlider {
            Layout.fillWidth: true

            label: qsTr("Adjust Pitch")
            from: -12; to: 12; stepSize: 0.5; ticks: 2; origin: 0; resetValue: 0
            value: root.on("scaletempo_pitch") ? root.opt("pitch-shift") : 0
            format: (v) => v.toFixed(1) + " " + qsTr("semitones")

            onMoved: (v) => {
                if (v !== 0)
                    EffectsController.setOption("pitch-shift", v)
                EffectsController.setFilterEnabled("scaletempo_pitch", v !== 0)
            }
        }
    }
}
