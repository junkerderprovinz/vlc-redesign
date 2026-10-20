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

import VLC.Style
import VLC.Widgets as Widgets
import VLC.Dialogs

// The default gains of the equalizer filter: the preamp and the ten bands
Rectangle {
    id: root

    readonly property var t: SettingsTheme

    property bool open: false

    readonly property var _bandNames: SettingsBridge.equalizerBandNames(!!frequencies.value)

    readonly property var gains: {
        const list = String(bandsOption.value ?? "").trim().split(/\s+/).map(parseFloat)
        const ret = []
        for (let i = 0; i < 10; ++i)
            ret.push(Number.isFinite(list[i]) ? list[i] : 0)
        return ret
    }

    function setGain(band, value) {
        const values = gains.slice()
        values[band] = Math.round(value * 10) / 10
        bandsOption.value = values.map((v) => v.toFixed(1)).join(" ")
    }

    function format(value) {
        return qsTr("%1 dB").arg(Number(value).toFixed(1))
    }

    implicitHeight: column.implicitHeight + column.anchors.topMargin + column.anchors.bottomMargin
    radius: t.dp(2)
    color: open ? t.bgA4 : t.bgB2

    ConfigOption { id: bandsOption; name: "equalizer-bands" }
    ConfigOption { id: preampOption; name: "equalizer-preamp" }
    ConfigOption { id: frequencies; name: "equalizer-vlcfreqs" }

    Column {
        id: column

        anchors.fill: parent
        anchors.topMargin: t.dp(6)
        anchors.bottomMargin: root.open ? t.dp(20) : t.dp(6)
        spacing: t.dp(24)

        T.AbstractButton {
            id: header

            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: headerRow.implicitWidth
            implicitHeight: t.dp(24)
            focusPolicy: Qt.StrongFocus
            text: root.open ? qsTr("Close Equalizer") : qsTr("Open Equalizer")

            Accessible.role: Accessible.Button

            onClicked: root.open = !root.open

            contentItem: Row {
                id: headerRow

                spacing: t.dp(10)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: header.text
                    color: header.hovered ? t.fg1 : t.fgA2
                    font.pixelSize: t.fontNormal
                }

                Widgets.IconLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    text: VLCIcons.chevron_down
                    rotation: root.open ? 0 : -90
                    color: t.fgA2
                    font.pixelSize: t.dp(24)
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: t.dp(8)
            visible: root.open

            Repeater {
                model: 11

                delegate: Column {
                    id: band

                    required property int index
                    readonly property bool preamp: index === 0
                    readonly property real gain: preamp ? Number(preampOption.value ?? 0) : root.gains[index - 1]

                    width: t.dp(60)
                    spacing: t.dp(12)

                    SettingsSlider {
                        anchors.horizontalCenter: parent.horizontalCenter
                        orientation: Qt.Vertical
                        from: -20
                        to: 20
                        stepSize: 0.1
                        modelValue: band.gain
                        toolTipTextProvider: (v) => root.format(v)

                        Accessible.name: bandLabel.text

                        onMoved: {
                            if (band.preamp)
                                preampOption.value = Math.round(value * 10) / 10
                            else
                                root.setGain(band.index - 1, value)
                        }
                    }

                    Item {
                        width: 1
                        height: t.dp(21)
                    }

                    Text {
                        id: bandLabel

                        anchors.horizontalCenter: parent.horizontalCenter
                        text: band.preamp ? qsTr("Preamp") : root._bandNames[band.index - 1]
                        color: t.fgA3
                        font.pixelSize: t.fontNormal
                    }

                    Widgets.FormTextField {
                        width: t.dp(60)
                        implicitHeight: t.dp(32)
                        horizontalAlignment: TextInput.AlignHCenter
                        leftPadding: t.dp(4)
                        rightPadding: t.dp(4)
                        font.pixelSize: t.fontSmall
                        value: root.format(band.gain)
                        borderWidth: activeFocus ? t.dp(1) : 0

                        onNumberCommitted: (number) => {
                            const clamped = Math.max(-20, Math.min(20, number))
                            if (band.preamp)
                                preampOption.value = Math.round(clamped * 10) / 10
                            else
                                root.setGain(band.index - 1, clamped)
                        }
                    }
                }
            }
        }
    }
}
