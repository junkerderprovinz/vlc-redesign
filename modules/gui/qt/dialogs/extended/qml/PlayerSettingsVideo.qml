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

import VLC.Dialogs
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

ColumnLayout {
    id: root

    // expanded cards, kept by the panel across tab changes
    property var expanded: ({})

    spacing: 0

    readonly property EffectsColors colors: EffectsColors { }

    function opt(name) {
        EffectsController.revision
        return EffectsController.option(name)
    }

    function on(module) {
        EffectsController.revision
        return EffectsController.isFilterEnabled(module)
    }

    // The picture adjustments share one filter, which runs as long as one of
    // them is away from its neutral value.
    readonly property var _adjustNeutral: ({ "hue": 0, "brightness": 1, "contrast": 1, "saturation": 1, "gamma": 1 })

    function adjustValue(name) {
        return on("adjust") ? opt(name) : _adjustNeutral[name]
    }

    function setAdjust(name, value) {
        const values = {}
        for (const key of Object.keys(_adjustNeutral))
            values[key] = (key === name) ? value : adjustValue(key)

        for (const key of Object.keys(values))
            EffectsController.setOption(key, values[key])

        const active = Object.keys(values).some((key) => Math.abs(values[key] - _adjustNeutral[key]) > 0.001)
        EffectsController.setFilterEnabled("adjust", active)
    }

    // These filters are off while their slider rests at the left end
    function levelValue(module, name, off) {
        return on(module) ? opt(name) : off
    }

    function setLevel(module, name, off, value) {
        if (value > off)
            EffectsController.setOption(name, value)
        EffectsController.setFilterEnabled(module, value > off)
    }

    component FilterHead : EffectsRow {
        minimumHeight: VLCStyle.dp(37, VLCStyle.scale)
    }

    component FilterSwitch : EffectsRow {
        id: filterSwitch

        property string module

        minimumHeight: VLCStyle.dp(44, VLCStyle.scale)
        Layout.leftMargin: 0

        EffectsSwitch {
            value: EffectsController.revision, EffectsController.isFilterEnabled(filterSwitch.module)
            onSwitched: (on) => EffectsController.setFilterEnabled(filterSwitch.module, on)
            Accessible.name: filterSwitch.label
        }
    }

    component ColorRow : EffectsRow {
        id: colorRow

        property string module
        property string option

        Layout.leftMargin: 0
        minimumHeight: VLCStyle.dp(32, VLCStyle.scale)

        EffectsColorField {
            rgb: EffectsController.revision, EffectsController.option(colorRow.option)
            Accessible.name: colorRow.label
            onPicked: (rgb) => EffectsController.setOption(colorRow.option, rgb)
        }

        EffectsSwitch {
            value: EffectsController.revision, EffectsController.isFilterEnabled(colorRow.module)
            onSwitched: (on) => EffectsController.setFilterEnabled(colorRow.module, on)
            Accessible.name: colorRow.label
        }
    }

    component CropLink : T.AbstractButton {
        id: link

        implicitWidth: VLCStyle.dp(30, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
        checkable: true

        readonly property EffectsColors colors: EffectsColors { }

        contentItem: Widgets.IconLabel {
            text: link.checked ? VLCIcons.link_active : VLCIcons.link
            color: link.checked ? link.colors.accent : link.colors.label
            font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
        }
    }

    EffectsSection {
        title: qsTr("Defaults")
        separator: false

        T.Label {
            Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(15, VLCStyle.scale)

            text: qsTr("Flip")
            color: root.colors.label
            font.pixelSize: VLCStyle.fontSize_normal
        }

        Widgets.SegmentedControl {
            readonly property var _types: ["", "hflip", "vflip"]

            Layout.fillWidth: true
            Layout.bottomMargin: VLCStyle.dp(11, VLCStyle.scale)

            model: [qsTr("None"), qsTr("Horizontal"), qsTr("Vertical")]
            Accessible.name: qsTr("Flip")

            Binding on currentIndex {
                value: root.on("transform") ? Math.max(0, ["", "hflip", "vflip"].indexOf(root.opt("transform-type"))) : 0
                restoreMode: Binding.RestoreNone
            }

            onActivated: (index) => {
                if (index > 0)
                    EffectsController.setOption("transform-type", _types[index])
                EffectsController.setFilterEnabled("transform", index > 0)
            }
        }

        EffectsRow {
            label: qsTr("Rotate")

            EffectsValueField {
                value: root.on("rotate") ? root.opt("rotate-angle") : 0
                format: (v) => Math.round(v) + " " + qsTr("deg")
                Accessible.name: qsTr("Rotate")

                onEdited: (v) => {
                    const angle = ((Math.round(v) % 360) + 360) % 360
                    if (angle !== 0)
                        EffectsController.setOption("rotate-angle", angle)
                    EffectsController.setFilterEnabled("rotate", angle !== 0)
                }
            }
        }

        EffectsRow {
            Layout.topMargin: VLCStyle.dp(15, VLCStyle.scale)
            label: qsTr("Zoom")

            EffectsComboBox {
                model: Player.zoom
                textRole: "display"
                checkable: true
                enabled: Player.hasVideoOutput
                Accessible.name: qsTr("Zoom")
            }
        }

        EffectsRow {
            Layout.topMargin: VLCStyle.dp(15, VLCStyle.scale)
            label: qsTr("Resolution")

            EffectsComboBox {
                readonly property var _choices: EffectsController.optionChoices("preferred-resolution")

                model: _choices
                textRole: "text"
                selectedIndex: {
                    const current = root.opt("preferred-resolution")
                    return Math.max(0, _choices.findIndex((c) => c.value === current))
                }
                onActivated: (index) => EffectsController.setOption("preferred-resolution", _choices[index].value)
                Accessible.name: qsTr("Resolution")
            }
        }

        EffectsRow {
            Layout.topMargin: VLCStyle.dp(15, VLCStyle.scale)
            label: qsTr("Aspect Ratio")

            EffectsComboBox {
                model: Player.aspectRatio
                textRole: "display"
                checkable: true
                enabled: Player.hasVideoOutput
                Accessible.name: qsTr("Aspect Ratio")
            }
        }

        EffectsRow {
            Layout.topMargin: VLCStyle.dp(15, VLCStyle.scale)
            label: qsTr("Crop")

            EffectsComboBox {
                model: Player.crop
                textRole: "display"
                checkable: true
                enabled: Player.hasVideoOutput
                Accessible.name: qsTr("Crop")
            }
        }

        EffectsRow {
            Layout.topMargin: VLCStyle.dp(15, VLCStyle.scale)
            label: qsTr("Render")

            EffectsComboBox {
                id: render

                property var _renderers: []
                property int _chosen: 0

                model: [qsTr("Local")].concat(_renderers)
                selectedIndex: Player.rendererManager.useRenderer ? _chosen : 0
                onActivated: (index) => {
                    _chosen = index
                    EffectsController.selectRenderer(index - 1)
                }
                Accessible.name: qsTr("Render")

                Instantiator {
                    model: Player.rendererManager

                    delegate: QtObject {
                        readonly property string name: model.name
                    }

                    onObjectAdded: render._renderers = Array.from({ length: count }, (_, i) => objectAt(i)?.name ?? "")
                    onObjectRemoved: render._renderers = Array.from({ length: count }, (_, i) => objectAt(i)?.name ?? "")
                }

                Connections {
                    target: render.popup

                    function onOpened() {
                        Player.rendererManager.StartScan()
                    }

                    function onClosed() {
                        Player.rendererManager.StopScan()
                    }
                }
            }
        }
    }

    EffectsSection {
        title: qsTr("Filters")
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)

        FilterHead { label: qsTr("Essential") }

        EffectsExpander {
            store: root.expanded
            key: "essential"

            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Hue")
                from: -180; to: 180; stepSize: 1; ticks: 2; resetValue: 0
                value: root.adjustValue("hue")
                onMoved: (v) => root.setAdjust("hue", v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Brightness")
                from: 0; to: 2; ticks: 2; resetValue: 1
                value: root.adjustValue("brightness")
                onMoved: (v) => root.setAdjust("brightness", v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Contrast")
                from: 0; to: 2; ticks: 2; resetValue: 1
                value: root.adjustValue("contrast")
                onMoved: (v) => root.setAdjust("contrast", v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Saturation")
                from: 0; to: 3; ticks: 3; resetValue: 1
                value: root.adjustValue("saturation")
                onMoved: (v) => root.setAdjust("saturation", v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Gamma")
                from: 0.01; to: 10; ticks: 10; resetValue: 1
                value: root.adjustValue("gamma")
                onMoved: (v) => root.setAdjust("gamma", v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Sharpen Sigma")
                from: 0; to: 2; ticks: 4; resetValue: 0
                value: root.levelValue("sharpen", "sharpen-sigma", 0)
                onMoved: (v) => root.setLevel("sharpen", "sharpen-sigma", 0, v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Banding Removal Radius")
                from: 4; to: 32; stepSize: 1; ticks: 7; resetValue: 4
                value: root.levelValue("gradfun", "gradfun-radius", 4)
                onMoved: (v) => root.setLevel("gradfun", "gradfun-radius", 4, v)
            }
            EffectsSlider {
                Layout.fillWidth: true
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                label: qsTr("Film Grain Variance")
                from: 0; to: 10; stepSize: 0.1; ticks: 10; resetValue: 0
                value: root.levelValue("grain", "grain-variance", 0)
                onMoved: (v) => root.setLevel("grain", "grain-variance", 0, v)
            }
        }
    }

    EffectsSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Crop") }

        EffectsExpander {
            store: root.expanded
            key: "crop"

            ColumnLayout {
                id: cropEdges

                property bool linkVertical: false
                property bool linkHorizontal: false
                readonly property var _crop: (EffectsController.revision, EffectsController.crop())

                Layout.fillWidth: true
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)

                spacing: VLCStyle.dp(16, VLCStyle.scale)
                enabled: Player.hasVideoOutput

                // edges are top, bottom, left, right; linked edges move together
                function setEdge(edge, value) {
                    const crop = _crop.slice()
                    value = Math.max(0, Math.round(value))
                    crop[edge] = value
                    if (edge < 2 && linkVertical)
                        crop[1 - edge] = value
                    else if (edge >= 2 && linkHorizontal)
                        crop[5 - edge] = value
                    EffectsController.setCrop(crop[0], crop[1], crop[2], crop[3])
                }

                Repeater {
                    model: [
                        { edges: [qsTr("Top"), qsTr("Bottom")], first: 0, link: qsTr("Link top and bottom") },
                        { edges: [qsTr("Left"), qsTr("Right")], first: 2, link: qsTr("Link left and right") }
                    ]

                    delegate: RowLayout {
                        id: cropRow

                        required property var modelData
                        readonly property bool vertical: modelData.first === 0

                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(8, VLCStyle.scale)

                        Repeater {
                            model: cropRow.modelData.edges

                            delegate: EffectsValueField {
                                id: edgeField

                                readonly property int edge: cropRow.modelData.first + index

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: VLCStyle.dp(33, VLCStyle.scale)

                                leftPadding: VLCStyle.dp(72, VLCStyle.scale)
                                value: cropEdges._crop[edge]
                                format: (v) => v + " " + qsTr("px")
                                Accessible.name: modelData

                                onEdited: (v) => cropEdges.setEdge(edge, v)

                                Widgets.LabelExt {
                                    anchors.left: parent.left
                                    anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: modelData
                                    color: edgeField.colors.label
                                    font.pixelSize: VLCStyle.fontSize_normal
                                }
                            }
                        }

                        CropLink {
                            checked: cropRow.vertical ? cropEdges.linkVertical : cropEdges.linkHorizontal
                            Accessible.name: cropRow.modelData.link

                            onToggled: {
                                if (cropRow.vertical)
                                    cropEdges.linkVertical = checked
                                else
                                    cropEdges.linkHorizontal = checked
                            }
                        }
                    }
                }
            }

        }
    }

    EffectsSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Colors") }

        EffectsExpander {
            store: root.expanded
            key: "colors"

            ColorRow {
                label: qsTr("Color Extraction")
                module: "extract"
                option: "extract-component"
            }

            ColorRow {
                Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
                label: qsTr("Color Threshold")
                module: "colorthres"
                option: "colorthres-color"
            }

            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Saturation")
                from: 0; to: 100; stepSize: 1
                value: root.opt("colorthres-saturationthres")
                onMoved: (v) => EffectsController.setOption("colorthres-saturationthres", Math.round(v))
            }

            EffectsSlider {
                Layout.fillWidth: true
                label: qsTr("Similarity")
                from: 0; to: 100; stepSize: 1
                value: root.opt("colorthres-similaritythres")
                onMoved: (v) => EffectsController.setOption("colorthres-similaritythres", Math.round(v))
            }

            FilterSwitch {
                Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
                label: qsTr("Negate Colors")
                module: "invert"
            }

            FilterSwitch {
                label: qsTr("Posterize")
                module: "posterize"
            }

            FilterSwitch {
                label: qsTr("Gradient")
                module: "gradient"
            }

            EffectsComboBox {
                readonly property var _choices: EffectsController.optionChoices("gradient-mode")

                Layout.fillWidth: true
                model: _choices
                textRole: "text"
                selectedIndex: {
                    const current = root.opt("gradient-mode")
                    return Math.max(0, _choices.findIndex((c) => c.value === current))
                }
                onActivated: (index) => EffectsController.setOption("gradient-mode", _choices[index].value)
                Accessible.name: qsTr("Gradient mode")
            }

            EffectsRow {
                Layout.leftMargin: 0
                minimumHeight: VLCStyle.dp(44, VLCStyle.scale)
                label: qsTr("Color")

                EffectsSwitch {
                    value: !!root.opt("gradient-color")
                    onSwitched: (on) => EffectsController.setOption("gradient-color", on)
                    Accessible.name: qsTr("Gradient color")
                }
            }

            EffectsRow {
                Layout.leftMargin: 0
                minimumHeight: VLCStyle.dp(44, VLCStyle.scale)
                label: qsTr("Cartoon")

                EffectsSwitch {
                    value: !!root.opt("gradient-cartoon")
                    onSwitched: (on) => EffectsController.setOption("gradient-cartoon", on)
                    Accessible.name: qsTr("Cartoon")
                }
            }

            EffectsSlider {
                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.dp(10, VLCStyle.scale)
                Layout.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                label: qsTr("Sepia Intensity")
                from: 0; to: 255; stepSize: 1; ticks: 3; resetValue: 0
                value: root.levelValue("sepia", "sepia-intensity", 0)
                onMoved: (v) => root.setLevel("sepia", "sepia-intensity", 0, Math.round(v))
            }
        }
    }

    EffectsSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Geometry") }

        EffectsExpander {
            store: root.expanded
            key: "geometry"

            FilterSwitch { label: qsTr("Magnification"); module: "magnify" }
            FilterSwitch { label: qsTr("Puzzle game"); module: "puzzle" }
            FilterSwitch { label: qsTr("Wave"); module: "wave" }
            FilterSwitch { label: qsTr("Ripple"); module: "ripple" }
        }
    }

    EffectsSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Overlay") }

        EffectsExpander {
            store: root.expanded
            key: "overlay"

            FilterSwitch { label: qsTr("Show text"); module: "marq" }

            EffectsRow {
                Layout.leftMargin: 0
                minimumHeight: VLCStyle.dp(44, VLCStyle.scale)
                label: qsTr("Text")

                EffectsValueField {
                    numeric: false
                    text: root.opt("marq-marquee")
                    Accessible.name: qsTr("Overlay text")
                    onEditingFinished: EffectsController.setOption("marq-marquee", text)
                }
            }

            FilterSwitch { label: qsTr("Show logo"); module: "logo" }

            EffectsRow {
                Layout.leftMargin: 0
                minimumHeight: VLCStyle.dp(44, VLCStyle.scale)
                label: qsTr("Logo file")

                EffectsValueField {
                    numeric: false
                    text: root.opt("logo-file")
                    Accessible.name: qsTr("Logo file")
                    onEditingFinished: EffectsController.setOption("logo-file", text)
                }
            }
        }
    }

    EffectsSection {
        bodySpacing: VLCStyle.dp(10, VLCStyle.scale)
        bodyTopMargin: VLCStyle.dp(20, VLCStyle.scale)

        FilterHead { label: qsTr("Advanced") }

        EffectsExpander {
            store: root.expanded
            key: "advanced"

            EffectsRow {
                Layout.leftMargin: 0
                label: qsTr("Deinterlace")

                EffectsComboBox {
                    implicitWidth: VLCStyle.dp(160, VLCStyle.scale)
                    model: Player.deinterlace
                    textRole: "display"
                    checkable: true
                    Accessible.name: qsTr("Deinterlace")
                }
            }

            EffectsRow {
                Layout.leftMargin: 0
                label: qsTr("Mode")

                EffectsComboBox {
                    implicitWidth: VLCStyle.dp(160, VLCStyle.scale)
                    model: Player.deinterlaceMode
                    textRole: "display"
                    checkable: true
                    Accessible.name: qsTr("Deinterlace mode")
                }
            }

            FilterSwitch { label: qsTr("Anti-flickering"); module: "antiflicker" }
            FilterSwitch { label: qsTr("Motion blur"); module: "motionblur" }
            FilterSwitch { label: qsTr("Denoiser"); module: "hqdn3d" }
        }
    }
}
