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

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Dialogs

// One setting: its label on the left and the control bound to the VLC option
// on the right. See SettingsPages for the row description.
FocusScope {
    id: root

    readonly property var t: SettingsTheme

    required property var row

    // search text to highlight in the label, the label becomes a link to the row
    property string query: ""

    signal jumpRequested()
    signal actionRequested(string name)

    readonly property bool fullWidth: ["equalizer", "addons", "shortcuts"].includes(row.type)

    // bumped whenever an option changes, so bindings that call into the bridge
    // are evaluated again
    property int revision: 0

    readonly property string type: {
        if (row.type !== "auto")
            return row.type
        if (option.type === ConfigOption.TYPE_BOOL)
            return "toggle"
        return option.choices.length > 0 ? "select" : "text"
    }

    readonly property string _deviceOption: {
        void revision
        const devices = { alsa: "alsa-audio-device", mmdevice: "mmdevice-audio-device",
                          waveout: "waveout-audio-device", directx: "directx-audio-device",
                          kai: "kai-audio-device" }
        let aout = String(aoutOption.value ?? "")
        if (aout === "" || aout === "any")
            aout = Qt.platform.os === "windows" ? "mmdevice" : ""
        return devices[aout] ?? ""
    }

    readonly property string optionName: {
        if (row.type === "device")
            return _deviceOption
        if (["action", "theme", "filter", "intf", "addons", "shortcuts", "caching"].includes(row.type))
            return ""
        return row.option ?? ""
    }

    readonly property bool available: {
        void revision
        switch (row.type) {
        case "theme":
        case "addons":
        case "shortcuts":
        case "caching":
            return true
        case "action":
            if (row.needsMediaLibrary)
                return MainCtx.mediaLibraryAvailable
            return !row.module || SettingsBridge.moduleExists(row.module)
        case "filter":
            return SettingsBridge.moduleExists(row.module)
        case "intf":
            return SettingsBridge.moduleExists(row.module ?? row.option)
        case "skin":
            return SettingsBridge.moduleExists("skins2")
        default:
            if (!option.available)
                return false
            if (row.module && !SettingsBridge.moduleExists(row.module))
                return false
            return true
        }
    }

    readonly property bool dependencyMet: {
        void revision
        const w = row.when
        if (w) {
            const v = dependency.value
            if (w.value !== undefined && v != w.value)
                return false
            if (w.not !== undefined && v == w.not)
                return false
        }
        if (row.whenModule && !SettingsBridge.hasModule(row.whenModule[0], row.whenModule[1]))
            return false
        if (row.whenIntf && !SettingsBridge.hasInterface(row.whenIntf))
            return false
        if (row.whenSkin && !String(intfOption.value ?? "").includes("skins2"))
            return false
        if (row.whenCustomCaching && cachingPreset() !== 0)
            return false
        return true
    }

    readonly property real scale: row.scale ?? 1

    function displayValue() {
        const v = option.value
        if (typeof v !== "number")
            return v ?? ""
        return v / scale
    }

    function formatNumber(v) {
        if (typeof v !== "number")
            return String(v)
        const rounded = Math.round(v * 100) / 100
        return String(rounded)
    }

    function writeDisplayValue(v) {
        if (option.type === ConfigOption.TYPE_INTEGER || option.type === ConfigOption.TYPE_COLOR)
            option.value = Math.round(v * scale)
        else if (option.type === ConfigOption.TYPE_FLOAT)
            option.value = v * scale
        else
            option.value = v
        afterWrite()
    }

    // keeps the filter that applies the option enabled while it differs from its default
    function afterWrite() {
        if (row.picture)
            SettingsBridge.syncFilter("video-filter", "adjust", ["hue", "brightness", "contrast", "saturation", "gamma"])
        else if (row.pitch)
            SettingsBridge.syncFilter("audio-filter", "scaletempo_pitch", ["pitch-shift"])
    }

    function cachingPreset() {
        void revision
        const f = Number(fileCaching.value)
        if (Number(networkCaching.value) === f * 3 && Number(discCaching.value) === f
                && Number(liveCaching.value) === f && [100, 200, 300, 500, 1000].includes(f))
            return f
        return 0
    }

    function hexColor(v) {
        let s = Number(v ?? 0).toString(16).toUpperCase()
        while (s.length < 6)
            s = "0" + s
        return "#" + s
    }

    function highlighted(text) {
        const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const at = query ? text.toLowerCase().indexOf(query.toLowerCase()) : -1
        if (at < 0)
            return esc(text)
        return esc(text.slice(0, at)) + "<font color=\"" + t.accent + "\">"
               + esc(text.slice(at, at + query.length)) + "</font>" + esc(text.slice(at + query.length))
    }

    function flash() {
        flashAnimation.restart()
    }

    visible: available
    enabled: dependencyMet
    opacity: dependencyMet ? 1 : 0.3

    implicitWidth: t.dp(784)
    implicitHeight: {
        if (fullWidth)
            return control.implicitHeight
        const content = Math.max(control.implicitHeight, labelRow.implicitHeight)
        return content + (row.tall ? t.dp(16) : t.dp(10))
    }

    activeFocusOnTab: false

    ConfigOption { id: option; name: root.optionName }
    ConfigOption { id: dependency; name: root.row.when ? root.row.when.option : "" }
    ConfigOption { id: aoutOption; name: root.row.type === "device" ? "aout" : "" }
    ConfigOption { id: intfOption; name: root.row.whenSkin ? "intf" : "" }

    ConfigOption { id: fileCaching; name: root.row.type === "caching" || root.row.whenCustomCaching ? "file-caching" : "" }
    ConfigOption { id: networkCaching; name: root.row.type === "caching" || root.row.whenCustomCaching ? "network-caching" : "" }
    ConfigOption { id: discCaching; name: root.row.type === "caching" || root.row.whenCustomCaching ? "disc-caching" : "" }
    ConfigOption { id: liveCaching; name: root.row.type === "caching" || root.row.whenCustomCaching ? "live-caching" : "" }

    ConfigOption { id: loopOption; name: root.row.type === "repeat" ? "loop" : "" }
    ConfigOption { id: effectOption; name: root.row.type === "visualizer" ? "effect-list" : "" }
    ConfigOption { id: presetBands; name: root.row.type === "eqPreset" ? "equalizer-bands" : "" }
    ConfigOption { id: presetPreamp; name: root.row.type === "eqPreset" ? "equalizer-preamp" : "" }

    Connections {
        target: SettingsBridge
        function onOptionChanged() { root.revision++ }
    }

    Rectangle {
        id: flashRect

        anchors.fill: parent
        anchors.leftMargin: -t.dp(8)
        anchors.rightMargin: -t.dp(8)
        radius: t.dp(4)
        color: t.accentBgBright
        opacity: 0

        SequentialAnimation {
            id: flashAnimation

            NumberAnimation { target: flashRect; property: "opacity"; to: 1; duration: 100 }
            NumberAnimation { target: flashRect; property: "opacity"; to: 0; duration: 1500; easing.type: Easing.OutQuad }
        }
    }

    Row {
        id: labelRow

        readonly property real available: root.width - control.width - t.dp(10)

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: t.dp(10)
        visible: !root.fullWidth

        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, labelRow.available - (infoIcon.visible ? t.dp(28) : 0))
            text: root.highlighted(root.row.label ?? "")
            textFormat: Text.StyledText
            color: jumpArea.containsMouse ? t.fg1 : t.fgA2
            font.pixelSize: t.fontNormal
            elide: Text.ElideRight

            MouseArea {
                id: jumpArea

                anchors.fill: parent
                enabled: root.query.length > 0
                hoverEnabled: enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.jumpRequested()
            }
        }

        Widgets.IconLabel {
            id: infoIcon

            anchors.verticalCenter: parent.verticalCenter
            visible: (root.row.info ?? "").length > 0
            text: VLCIcons.info
            color: infoHover.hovered ? t.fgA2 : t.fgA4
            font.pixelSize: t.dp(18)

            HoverHandler { id: infoHover }

            Widgets.ToolTipExt {
                visible: infoHover.hovered
                text: root.row.info ?? ""
                delay: VLCStyle.delayToolTipAppear
            }
        }
    }

    Loader {
        id: control

        anchors.right: parent.right
        anchors.left: root.fullWidth ? parent.left : undefined
        anchors.verticalCenter: parent.verticalCenter

        focus: true

        sourceComponent: {
            switch (root.type) {
            case "toggle":
            case "filter":
            case "intf":
            case "skin":
            case "opacityToggle":
                return toggleComponent
            case "select":
            case "screen":
            case "repeat":
            case "visualizer":
            case "eqPreset":
            case "device":
            case "caching":
            case "opacitySelect":
                return selectComponent
            case "text":
                return textComponent
            case "file":
            case "folder":
                return fileComponent
            case "range":
                return rangeComponent
            case "color":
                return colorComponent
            case "action":
                return actionComponent
            case "theme":
                return themeComponent
            case "accent":
                return accentComponent
            case "startVolume":
                return startVolumeComponent
            case "equalizer":
                return equalizerComponent
            case "addons":
                return addonsComponent
            case "shortcuts":
                return shortcutsComponent
            }
            return null
        }
    }

    Component {
        id: toggleComponent

        Widgets.CheckButton {
            readonly property bool state: {
                void root.revision
                switch (root.type) {
                case "filter":
                    return SettingsBridge.hasModule(root.row.option, root.row.module)
                case "intf":
                    return SettingsBridge.hasInterface(root.row.option)
                case "skin":
                    return String(option.value ?? "").includes("skins2")
                case "opacityToggle":
                    return Number(option.value) > 0
                default:
                    return root.row.invert ? !option.value : !!option.value
                }
            }

            // the option is the state; clicking writes it and the binding follows
            checkable: false
            checked: state

            Accessible.name: root.row.label

            onClicked: {
                const on = !state
                switch (root.type) {
                case "filter":
                    SettingsBridge.setModule(root.row.option, root.row.module, on)
                    break
                case "intf":
                    SettingsBridge.setInterface(root.row.option, on)
                    break
                case "skin":
                    option.value = on ? "skins2,any" : ""
                    break
                case "opacityToggle":
                    option.value = on ? 128 : 0
                    break
                default:
                    option.value = root.row.invert ? !on : on
                }
            }
        }
    }

    Component {
        id: selectComponent

        Widgets.ComboBoxExt {
            id: combo

            readonly property var choices: {
                void root.revision
                switch (root.type) {
                case "screen": {
                    const list = [{ value: -1, text: qsTr("Current screen") }]
                    const screens = Qt.application.screens
                    for (let i = 0; i < screens.length; ++i)
                        list.push({ value: i, text: screens[i].name })
                    return list
                }
                case "repeat":
                    return [{ value: "off", text: qsTr("Off") },
                            { value: "one", text: qsTr("Repeat one") },
                            { value: "all", text: qsTr("Repeat all") }]
                case "visualizer": {
                    const list = [{ value: "none", text: qsTr("Disabled") }]
                    if (SettingsBridge.moduleExists("visual")) {
                        list.push({ value: "spectrometer", text: qsTr("Spectrometer") },
                                  { value: "scope", text: qsTr("Scope") },
                                  { value: "spectrum", text: qsTr("Spectrum") },
                                  { value: "vuMeter", text: qsTr("VU meter") })
                    }
                    for (const c of option.choices) {
                        if (!["", "any", "none", "visual"].includes(c.value))
                            list.push(c)
                    }
                    return list
                }
                case "caching":
                    return [{ value: 0, text: qsTr("Custom") },
                            { value: 100, text: qsTr("Lowest latency") },
                            { value: 200, text: qsTr("Low latency") },
                            { value: 300, text: qsTr("Normal") },
                            { value: 500, text: qsTr("High latency") },
                            { value: 1000, text: qsTr("Higher latency") }]
                case "opacitySelect":
                    return [{ value: false, text: qsTr("None") }, { value: true, text: qsTr("Box") }]
                }
                const list = root.row.choices ?? option.choices
                if (list.length === 0 && option.type === ConfigOption.TYPE_BOOL)
                    return [{ value: false, text: qsTr("Off") }, { value: true, text: qsTr("On") }]
                return list
            }

            readonly property var current: {
                void root.revision
                switch (root.type) {
                case "repeat":
                    return option.value ? "one" : (loopOption.value ? "all" : "off")
                case "visualizer": {
                    const v = String(option.value ?? "")
                    if (v === "visual")
                        return String(effectOption.value ?? "spectrum")
                    return v === "" || v === "any" ? "none" : v
                }
                case "caching":
                    return root.cachingPreset()
                case "opacitySelect":
                    return Number(option.value) > 0
                }
                return option.value
            }

            readonly property int matchingIndex: {
                for (let i = 0; i < choices.length; ++i) {
                    const v = choices[i].value
                    // float options come back with single precision
                    if (typeof v === "number" && typeof current === "number") {
                        if (Math.abs(v - current) < 1e-4)
                            return i
                    } else if (v == current) {
                        return i
                    }
                }
                return -1
            }

            implicitWidth: t.controlWidth
            implicitHeight: t.dp(36)
            font.pixelSize: t.fontNormal

            model: choices
            textRole: "text"
            valueRole: "value"
            currentIndex: matchingIndex
            displayText: matchingIndex >= 0 ? choices[matchingIndex].text
                                            : (root.formatNumber(current ?? "") || qsTr("Default"))

            Accessible.name: root.row.label

            onActivated: (index) => {
                const v = choices[index].value
                switch (root.type) {
                case "repeat":
                    option.value = (v === "one")
                    loopOption.value = (v === "all")
                    break
                case "visualizer":
                    if (["spectrometer", "scope", "spectrum", "vuMeter"].includes(v)) {
                        effectOption.value = v
                        option.value = "visual"
                    } else {
                        option.value = v
                    }
                    break
                case "caching":
                    if (v > 0) {
                        fileCaching.value = v
                        networkCaching.value = v * 3
                        discCaching.value = v
                        liveCaching.value = v
                    }
                    break
                case "opacitySelect":
                    if (!v)
                        option.value = 0
                    else if (Number(option.value) === 0)
                        option.value = 128
                    break
                case "eqPreset": {
                    option.value = v
                    const preset = SettingsBridge.equalizerPreset(v)
                    if (preset.bands) {
                        presetBands.value = preset.bands.map((b) => b.toFixed(1)).join(" ")
                        presetPreamp.value = preset.preamp
                    }
                    break
                }
                default:
                    option.value = v
                    root.afterWrite()
                }
                currentIndex = Qt.binding(() => matchingIndex)
            }
        }
    }

    Component {
        id: textComponent

        SettingsTextField {
            id: field

            compact: root.row.compact ?? false
            unit: root.row.unit ?? ""
            placeholderText: root.row.placeholder ?? ""
            echoMode: option.type === ConfigOption.TYPE_PASSWORD ? TextInput.Password : TextInput.Normal
            value: {
                void root.revision
                return root.formatNumber(root.displayValue())
            }

            Accessible.name: root.row.label

            onCommitted: (text) => {
                if (option.type === ConfigOption.TYPE_STRING || option.type === ConfigOption.TYPE_PASSWORD
                        || option.type === ConfigOption.TYPE_FONT || option.type === ConfigOption.TYPE_FILE
                        || option.type === ConfigOption.TYPE_DIRECTORY || option.type === ConfigOption.TYPE_MODULE) {
                    option.value = text.trim()
                    return
                }
                const v = parseFloat(text.replace(",", "."))
                if (Number.isFinite(v))
                    root.writeDisplayValue(v)
                else
                    field.text = field.value
            }
        }
    }

    Component {
        id: fileComponent

        Row {
            spacing: t.dp(10)

            SettingsTextField {
                id: path

                width: t.dp(210)
                compact: root.row.compact ?? false
                value: String(option.value ?? "")
                Accessible.name: root.row.label
                onCommitted: (text) => option.value = text.trim()
            }

            SettingsButton {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Browse")
                onClicked: {
                    const picked = root.type === "folder"
                                   ? SettingsBridge.browseDirectory(path.value)
                                   : SettingsBridge.browseFile(path.value, root.row.save ?? false)
                    if (picked.length > 0)
                        option.value = picked
                }
            }
        }
    }

    Component {
        id: rangeComponent

        Column {
            spacing: t.dp(4)

            SettingsSlider {
                id: slider

                width: t.controlWidth
                from: root.row.from
                to: root.row.to
                stepSize: root.row.step
                snapMode: T.Slider.SnapAlways
                modelValue: {
                    void root.revision
                    return Number(root.displayValue())
                }
                toolTipTextProvider: (v) => root.formatNumber(Math.round(v / stepSize) * stepSize)
                                            + (root.row.unit ? " " + root.row.unit : "")

                Accessible.name: root.row.label

                onMoved: root.writeDisplayValue(value)
            }

            Item {
                visible: (root.row.labels ?? []).length > 0
                width: t.controlWidth
                height: t.dp(15)

                Repeater {
                    model: root.row.labels ?? []

                    delegate: Text {
                        required property int index
                        required property string modelData

                        readonly property int last: (root.row.labels.length - 1)
                        readonly property real at: index / last

                        x: Math.max(0, Math.min(parent.width - width,
                                                t.dp(4) + (parent.width - t.dp(8)) * at - width * at))
                        text: modelData
                        color: t.fgA3
                        font.pixelSize: t.fontSmall
                    }
                }
            }
        }
    }

    Component {
        id: colorComponent

        Rectangle {
            implicitWidth: t.controlWidth
            implicitHeight: t.dp(32)
            radius: t.dp(6)
            color: t.bgB2

            SettingsTextField {
                id: hexField

                anchors.left: parent.left
                anchors.right: chip.left
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                borderWidth: 0
                backgroundColor: "transparent"
                value: {
                    void root.revision
                    return root.hexColor(option.value)
                }
                Accessible.name: root.row.label

                onCommitted: (text) => {
                    const m = /^#?([0-9a-fA-F]{6})$/.exec(text.trim())
                    if (m)
                        option.value = parseInt(m[1], 16)
                    else
                        hexField.text = hexField.value
                }
            }

            T.AbstractButton {
                id: chip

                anchors.right: parent.right
                anchors.rightMargin: t.dp(5)
                anchors.verticalCenter: parent.verticalCenter
                width: t.dp(22)
                height: t.dp(22)

                Accessible.name: qsTr("Pick a color")

                onClicked: {
                    picker.setColor(hexField.value)
                    picker.open()
                }

                background: Rectangle {
                    radius: t.dp(2)
                    color: hexField.value
                    border.width: t.dp(1.5)
                    border.color: Qt.rgba(1, 1, 1, 0.21)
                }

                SettingsColorPicker {
                    id: picker

                    x: chip.width - width
                    y: chip.height + t.dp(6)

                    onPicked: (c) => option.value = parseInt(c.toString().slice(1, 7), 16)
                }
            }
        }
    }

    Component {
        id: actionComponent

        SettingsButton {
            id: button

            readonly property string label: root.row.button

            width: root.row.wide ? t.controlWidth : implicitWidth
            text: label
            danger: root.row.danger ?? false

            Timer {
                id: resetLabel

                onTriggered: {
                    button.armed = false
                    button.text = button.label
                }
            }

            onClicked: {
                if (root.row.confirm && !armed) {
                    armed = true
                    text = root.row.confirm
                    resetLabel.interval = 3000
                    resetLabel.restart()
                    return
                }
                armed = false
                root.actionRequested(root.row.run)
                if (root.row.done) {
                    text = root.row.done
                    resetLabel.interval = 1500
                    resetLabel.restart()
                } else {
                    text = label
                }
            }
        }
    }

    Component {
        id: themeComponent

        Widgets.SegmentedControl {
            // schemes in the order of the design, as rows of MainCtx.colorScheme
            readonly property var schemes: [2, 1, 0]

            implicitWidth: t.controlWidth
            segmentHeight: t.dp(32)
            font.pixelSize: t.fontNormal

            model: [qsTr("Dark"), qsTr("Light"), qsTr("System")]
            currentIndex: schemes.indexOf(MainCtx.colorScheme.scheme)

            Accessible.name: root.row.label

            onActivated: (index) => {
                MainCtx.colorScheme.setData(MainCtx.colorScheme.index(schemes[index], 0), true, Qt.CheckStateRole)
                currentIndex = Qt.binding(() => schemes.indexOf(MainCtx.colorScheme.scheme))
            }
        }
    }

    Component {
        id: accentComponent

        SettingsSwatches {
            id: swatchRow

            readonly property var presets: VLCStyle.accentColors
            readonly property int presetIndex: {
                const current = MainCtx.accentColor.toString().toLowerCase()
                return presets.findIndex((c) => c.toLowerCase() === current)
            }

            swatches: {
                const list = presets.map((c) => ({ color: c, text: c }))
                list.push({ color: presetIndex < 0 ? MainCtx.accentColor.toString() : null,
                            text: qsTr("Custom color") })
                return list
            }
            currentIndex: presetIndex < 0 ? presets.length : presetIndex

            onActivated: (index) => {
                if (index === 0) {
                    MainCtx.accentColor = undefined
                } else if (index < presets.length) {
                    MainCtx.accentColor = presets[index]
                } else {
                    accentPicker.setColor(MainCtx.accentColor)
                    accentPicker.open()
                }
            }

            SettingsColorPicker {
                id: accentPicker

                x: swatchRow.width - width
                y: swatchRow.height + t.dp(6)

                onPicked: (c) => MainCtx.accentColor = c
            }
        }
    }

    Component {
        id: startVolumeComponent

        Rectangle {
            id: choices

            readonly property bool remember: {
                void root.revision
                return !!option.value
            }

            implicitWidth: t.controlWidth
            implicitHeight: column.implicitHeight + t.dp(4)
            radius: t.dp(6)
            color: t.bgB2

            Column {
                id: column

                anchors.fill: parent
                anchors.margins: t.dp(2)
                spacing: t.dp(2)

                T.AbstractButton {
                    id: rememberChoice

                    width: parent.width
                    height: t.dp(36)
                    text: qsTr("Remember last volume")
                    focusPolicy: Qt.StrongFocus

                    Accessible.role: Accessible.RadioButton
                    Accessible.checked: choices.remember

                    onClicked: option.value = true

                    background: Rectangle {
                        radius: t.dp(4)
                        color: choices.remember ? t.accentBgBright : t.bgA4
                    }

                    contentItem: Text {
                        leftPadding: t.dp(12)
                        verticalAlignment: Text.AlignVCenter
                        text: rememberChoice.text
                        color: choices.remember ? t.accent : t.fgA3
                        font.pixelSize: t.fontNormal
                    }
                }

                Rectangle {
                    width: parent.width
                    height: t.dp(36)
                    radius: t.dp(4)
                    color: !choices.remember ? t.accentBgBright : t.bgA4
                    enabled: SettingsBridge.hasDefaultVolume

                    MouseArea {
                        anchors.fill: parent
                        onPressed: option.value = false
                    }

                    Text {
                        id: fixedLabel

                        anchors.left: parent.left
                        anchors.leftMargin: t.dp(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Always starts at:")
                        color: !choices.remember ? t.accent : t.fgA3
                        font.pixelSize: t.fontNormal
                    }

                    SettingsTextField {
                        anchors.left: fixedLabel.right
                        anchors.leftMargin: t.dp(10)
                        anchors.right: parent.right
                        anchors.rightMargin: t.dp(2)
                        anchors.verticalCenter: parent.verticalCenter
                        compact: true
                        borderWidth: 0
                        radius: t.dp(2)
                        unit: "%"
                        opacity: choices.remember ? 0.4 : 1
                        value: {
                            void root.revision
                            const volume = SettingsBridge.defaultVolume()
                            return volume >= 0 ? String(volume) : ""
                        }
                        Accessible.name: qsTr("Startup volume level")

                        onActiveFocusChanged: {
                            if (activeFocus)
                                option.value = false
                        }
                        onCommitted: (text) => {
                            const v = parseInt(text)
                            if (Number.isFinite(v))
                                SettingsBridge.setDefaultVolume(Math.max(0, Math.min(v, 300)))
                        }
                    }
                }
            }
        }
    }

    Component {
        id: equalizerComponent

        SettingsEqualizer { }
    }

    Component {
        id: addonsComponent

        SettingsAddons { }
    }

    Component {
        id: shortcutsComponent

        Column {
            Repeater {
                model: root.row.keys

                delegate: Item {
                    required property var modelData

                    width: parent.width
                    height: t.dp(42)

                    ConfigOption { id: key; name: modelData.option }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        color: t.fgA2
                        font.pixelSize: t.fontNormal
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: t.dp(6)

                        Repeater {
                            // several bindings are separated by tabs, show the first one
                            model: String(key.value ?? "").split("\t")[0].split("+").filter((k) => k.length > 0)

                            delegate: Rectangle {
                                required property string modelData

                                width: Math.max(t.dp(28), keyLabel.implicitWidth + t.dp(16))
                                height: t.dp(28)
                                radius: t.dp(4)
                                color: t.bgB2
                                border.width: t.dp(1)
                                border.color: t.bgA4

                                Text {
                                    id: keyLabel

                                    anchors.centerIn: parent
                                    text: modelData
                                    color: t.fgA2
                                    font.pixelSize: t.fontSmall
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
