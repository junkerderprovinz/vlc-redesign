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
import VLC.Dialogs
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

// Floating panel of the player with the playback settings and the audio,
// video and subtitle effects.
T.Pane {
    id: root

    enum Tab {
        Playback,
        Video,
        Audio,
        Subtitles
    }

    property int currentTab: MainCtx.playerSettingsTab

    signal closeRequested()

    implicitWidth: VLCStyle.dp(400, VLCStyle.scale)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    focusPolicy: Qt.NoFocus

    Keys.onEscapePressed: root.closeRequested()

    readonly property EffectsColors colors: EffectsColors { }

    // cards the user opened, kept while the panel exists
    readonly property var _expanded: ({ })

    readonly property var _pages: [playbackPage, videoPage, audioPage, subtitlesPage]

    // The options and filters a preset of each tab holds
    readonly property var _presetFilters: [
        [],
        ["adjust", "sharpen", "gradfun", "grain", "sepia", "invert", "posterize", "transform", "rotate"],
        ["equalizer", "compressor", "spatializer", "stereo_widen", "scaletempo_pitch"],
        []
    ]
    readonly property var _presetOptions: [
        [],
        ["hue", "brightness", "contrast", "saturation", "gamma", "sharpen-sigma", "gradfun-radius",
         "grain-variance", "sepia-intensity", "transform-type", "rotate-angle"],
        ["equalizer-preset", "equalizer-preamp", "equalizer-bands", "equalizer-2pass",
         "compressor-rms-peak", "compressor-attack", "compressor-release", "compressor-threshold",
         "compressor-ratio", "compressor-knee", "compressor-makeup-gain",
         "spatializer-roomsize", "spatializer-width", "spatializer-wet", "spatializer-dry",
         "spatializer-damp", "stereowiden-delay", "stereowiden-feedback", "stereowiden-crossfeed",
         "stereowiden-dry-mix", "pitch-shift"],
        ["freetype-color", "freetype-outline-color", "freetype-outline-thickness",
         "freetype-background-opacity", "sub-margin", "subsdec-formatting"]
    ]

    readonly property var _builtinPresets: [
        {
            name: qsTr("Anime"),
            values: {
                "filter:adjust": true, "saturation": 1.3, "contrast": 1.1,
                "filter:sharpen": true, "sharpen-sigma": 0.5,
                "filter:gradfun": true, "gradfun-radius": 20,
                "filter:equalizer": true, "equalizer-preset": "pop", "equalizer-preamp": 6,
                "equalizer-bands": "-1.6 4.8 7.2 8 5.6 0 -2.4 -2.4 -1.6 -1.6"
            }
        },
        {
            name: qsTr("Loud and then Quiet Movies"),
            values: {
                "filter:compressor": true, "compressor-threshold": -20,
                "compressor-ratio": 6, "compressor-makeup-gain": 10,
                "filter:adjust": true, "brightness": 1.1, "gamma": 1.2
            }
        }
    ]

    // the preset last picked on each tab
    property var _chosenPresets: ["", "", "", ""]

    function _presetsFor(tab) {
        const options = _presetOptions[tab]
        const filters = _presetFilters[tab]
        const holds = (preset) => Object.keys(preset.values).some(
                          (key) => options.includes(key) || filters.includes(key.replace(/^filter:/, "")))
        return EffectsController.presets.concat(_builtinPresets).filter(holds)
    }

    function _applyPreset(tab, values) {
        for (const option of _presetOptions[tab]) {
            const value = (values && option in values) ? values[option]
                                                        : EffectsController.defaultOption(option)
            EffectsController.setOption(option, value)
        }
        for (const filter of _presetFilters[tab])
            EffectsController.setFilterEnabled(filter, !!(values && values["filter:" + filter]))
    }

    function _saveNewPreset(tab) {
        const values = {}
        for (const option of _presetOptions[tab])
            values[option] = EffectsController.option(option)
        for (const filter of _presetFilters[tab])
            values["filter:" + filter] = EffectsController.isFilterEnabled(filter)

        const names = EffectsController.presets.map((p) => p.name)
        let n = 1
        let name
        do {
            name = qsTr("Custom Preset %1").arg(String(n++).padStart(2, "0"))
        } while (names.includes(name))

        EffectsController.savePreset(name, values)
        return name
    }

    function _choosePreset(name) {
        const chosen = _chosenPresets.slice()
        chosen[currentTab] = name
        _chosenPresets = chosen
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root.colors.panel

        Widgets.RoundedRectangleShadow {
            z: -1
            color: Qt.rgba(0, 0, 0, root.colors.tokens.isDark ? 0.46 : 0.18)
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)

            radius: VLCStyle.dp(10, VLCStyle.scale)
            color: root.colors.field

            // square off the bottom corners
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)

                spacing: 0

                Repeater {
                    model: [
                        { tab: PlayerSettingsPanel.Tab.Playback, text: qsTr("Playback"), glyph: VLCIcons.playback, slug: "playback" },
                        { tab: PlayerSettingsPanel.Tab.Video, text: qsTr("Video"), glyph: VLCIcons.video, slug: "video" },
                        { tab: PlayerSettingsPanel.Tab.Audio, text: qsTr("Audio"), glyph: VLCIcons.audio, slug: "audio" },
                        { tab: PlayerSettingsPanel.Tab.Subtitles, text: qsTr("Subtitles"), glyph: VLCIcons.subtitles, slug: "subtitles" }
                    ]

                    delegate: Widgets.TabButtonExt {
                        required property var modelData
                        required property int index

                        readonly property bool _outer: (index === 0 || index === 3)

                        Layout.fillHeight: true
                        Layout.fillWidth: _outer
                        Layout.preferredWidth: _outer ? -1 : VLCStyle.dp(85, VLCStyle.scale)

                        indicatorMargin: _outer ? VLCStyle.margin_xsmall : VLCStyle.margin_small

                        text: modelData.text
                        font.pixelSize: VLCStyle.fontSize_small
                        checked: root.currentTab === modelData.tab
                        iconTxt: checked ? "" : modelData.glyph
                        checkedIconSource: SVGColorImage.colorize("qrc:///icons/figma/" + modelData.slug + "-duo.svg")
                                                        .color1(root.colors.text)
                                                        .color2(root.colors.accent)
                                                        .accent(root.colors.accent).uri()

                        Accessible.role: Accessible.PageTab

                        onClicked: MainCtx.playerSettingsTab = modelData.tab
                    }
                }
            }
        }

        Flickable {
            id: flickable

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: width
            contentHeight: pageLoader.height
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            Loader {
                id: pageLoader

                width: flickable.width

                sourceComponent: root._pages[root.currentTab] ?? videoPage

                onLoaded: flickable.contentY = 0
            }
        }

        Rectangle {
            visible: root.currentTab !== PlayerSettingsPanel.Tab.Playback

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border

            color: root.colors.divider
        }

        ColumnLayout {
            visible: root.currentTab !== PlayerSettingsPanel.Tab.Playback

            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)

            spacing: VLCStyle.dp(10, VLCStyle.scale)

            T.AbstractButton {
                id: presetButton

                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(38, VLCStyle.scale)

                leftPadding: VLCStyle.dp(16, VLCStyle.scale)
                rightPadding: VLCStyle.dp(16, VLCStyle.scale)

                text: root._chosenPresets[root.currentTab] || qsTr("Default Preset")
                Accessible.name: qsTr("Preset")

                onClicked: presetMenu.popup(presetButton, 0, -presetMenu.implicitHeight - VLCStyle.margin_xsmall)

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: (presetButton.hovered || presetMenu.visible) ? root.colors.hover : "transparent"
                    border.width: presetButton.visualFocus ? VLCStyle.focus_border : 0
                    border.color: root.colors.visualFocus
                }

                contentItem: RowLayout {
                    T.Label {
                        Layout.fillWidth: true

                        text: presetButton.text
                        color: root.colors.text
                        font.pixelSize: VLCStyle.fontSize_normal
                        elide: Text.ElideRight
                    }

                    Widgets.IconLabel {
                        text: presetMenu.visible ? VLCIcons.chevron_down : VLCIcons.chevron_up
                        color: root.colors.text
                        font.pixelSize: VLCStyle.icon_normal
                    }
                }
            }

            T.AbstractButton {
                id: advancedButton

                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                text: qsTr("Open Advanced Settings")

                // the extended dialog keeps every filter of the panel and more
                onClicked: {
                    if (root.currentTab === PlayerSettingsPanel.Tab.Audio)
                        DialogsProvider.extendedDialogTab(0)
                    else if (root.currentTab === PlayerSettingsPanel.Tab.Video)
                        DialogsProvider.extendedDialogTab(1)
                    else
                        DialogsProvider.prefsDialog()
                }

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: advancedButton.hovered ? root.colors.hover : "transparent"
                    border.width: advancedButton.visualFocus ? VLCStyle.focus_border : 0
                    border.color: root.colors.visualFocus
                }

                contentItem: Item {
                    implicitHeight: advancedRow.implicitHeight

                    Row {
                        id: advancedRow

                        anchors.centerIn: parent
                        spacing: VLCStyle.dp(6, VLCStyle.scale)

                        Widgets.IconLabel {
                            anchors.verticalCenter: parent.verticalCenter

                            text: VLCIcons.settings
                            color: advancedButton.hovered ? root.colors.text : root.colors.label
                            font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                        }

                        T.Label {
                            anchors.verticalCenter: parent.verticalCenter

                            text: advancedButton.text
                            color: advancedButton.hovered ? root.colors.text : root.colors.label
                            font.pixelSize: VLCStyle.fontSize_normal
                        }
                    }
                }
            }
        }
    }

    Widgets.MenuExt {
        id: presetMenu

        width: presetButton.width

        Widgets.MenuItemExt {
            iconTxt: VLCIcons.add
            text: qsTr("New Preset")
            onTriggered: root._choosePreset(root._saveNewPreset(root.currentTab))
        }

        Instantiator {
            model: presetMenu.visible ? root._presetsFor(root.currentTab) : []

            delegate: Widgets.MenuItemExt {
                required property var modelData

                iconTxt: VLCIcons.more
                text: modelData.name
                checkable: true
                checked: root._chosenPresets[root.currentTab] === modelData.name

                onTriggered: {
                    root._applyPreset(root.currentTab, modelData.values)
                    root._choosePreset(modelData.name)
                }
            }

            onObjectAdded: (index, object) => presetMenu.insertItem(index + 1, object)
            onObjectRemoved: (index, object) => presetMenu.removeItem(object)
        }

        Widgets.MenuItemExt {
            text: qsTr("Default Preset")
            checkable: true
            checked: !root._chosenPresets[root.currentTab]

            onTriggered: {
                root._applyPreset(root.currentTab, null)
                root._choosePreset("")
            }
        }

        Widgets.MenuSeparatorExt {
            visible: EffectsController.presets.length > 0
        }

        Widgets.MenuExt {
            id: removeMenu

            title: qsTr("Remove Preset")
            enabled: EffectsController.presets.length > 0

            Instantiator {
                model: presetMenu.visible ? EffectsController.presets : []

                delegate: Widgets.MenuItemExt {
                    required property var modelData

                    text: modelData.name

                    onTriggered: {
                        EffectsController.removePreset(modelData.name)
                        if (root._chosenPresets.includes(modelData.name))
                            root._chosenPresets = root._chosenPresets.map((n) => n === modelData.name ? "" : n)
                    }
                }

                onObjectAdded: (index, object) => removeMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => removeMenu.removeItem(object)
            }
        }
    }

    Component {
        id: playbackPage

        PlayerSettingsPlayback { }
    }

    Component {
        id: videoPage

        PlayerSettingsVideo { expanded: root._expanded }
    }

    Component {
        id: audioPage

        PlayerSettingsAudio { expanded: root._expanded }
    }

    Component {
        id: subtitlesPage

        PlayerSettingsSubtitles { expanded: root._expanded }
    }
}
