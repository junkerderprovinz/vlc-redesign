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
import VLC.Dialogs

FocusScope {
    id: root

    required property FirstRunController controller

    readonly property bool hasAside: true

    // Each entry names the hotkey options of its alternatives, so the keys
    // shown are the ones currently configured.
    readonly property var columns: [
        [
            { label: qsTr("Play / Pause"), keys: ["key-play-pause"] },
            { label: qsTr("Seek Backward / Forward"), keys: ["key-jump-extrashort", "key-jump+extrashort"] },
            { label: qsTr("Previous / Next Item"), keys: ["key-prev", "key-next"] },
            { label: qsTr("Previous / Next Frame"), keys: ["key-frame-previous", "key-frame-next"] },
            { label: qsTr("Cycle Subtitle Track"), keys: ["key-subtitle-track"] },
            { label: qsTr("Cycle Audio Track"), keys: ["key-audio-track"] }
        ],
        [
            { label: qsTr("Toggle Fullscreen"), keys: ["key-toggle-fullscreen"] },
            { label: qsTr("Increase / Decrease Volume"), keys: ["key-vol-up", "key-vol-down"] },
            { label: qsTr("Mute"), keys: ["key-vol-mute"] },
            { label: qsTr("Cycle Loop Mode"), keys: ["key-loop"] },
            { label: qsTr("Take a Snapshot"), keys: ["key-snapshot"] },
            { label: qsTr("Record"), keys: ["key-record"] }
        ]
    ]

    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    T.Label {
        anchors.left: parent.left
        anchors.right: parent.right
        y: VLCStyle.dp(60, VLCStyle.scale)

        text: qsTr("Learn the basic keyboard shortcuts.")
        color: VLCStyle.palette.fgA1
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
        lineHeight: VLCStyle.dp(42, VLCStyle.scale)
        lineHeightMode: Text.FixedHeight
    }

    Row {
        x: VLCStyle.dp(62, VLCStyle.scale)
        y: VLCStyle.dp(154, VLCStyle.scale)

        spacing: VLCStyle.dp(150, VLCStyle.scale)

        Repeater {
            model: root.columns

            delegate: Column {
                id: column

                required property var modelData

                width: VLCStyle.dp(393, VLCStyle.scale)
                spacing: VLCStyle.dp(40, VLCStyle.scale)

                Repeater {
                    model: column.modelData

                    delegate: Row {
                        id: shortcut

                        required property var modelData

                        readonly property var alternatives: modelData.keys.map((name) => root.controller.hotkey(name))
                                                                          .filter((keys) => keys.length > 0)

                        // modifiers shared by every alternative are shown once, in front
                        readonly property var modifiers: {
                            if (alternatives.length < 2)
                                return []
                            const prefix = alternatives[0].slice(0, -1).join("+")
                            const shared = alternatives.every((keys) => keys.slice(0, -1).join("+") === prefix)
                            return (shared && prefix !== "") ? alternatives[0].slice(0, -1) : []
                        }

                        readonly property var keys: modifiers.length > 0 ? alternatives.map((keys) => keys.slice(-1))
                                                                         : alternatives

                        height: VLCStyle.dp(42, VLCStyle.scale)
                        spacing: VLCStyle.dp(20, VLCStyle.scale)

                        Accessible.role: Accessible.StaticText
                        Accessible.name: modelData.label + ": "
                                         + alternatives.map((keys) => keys.join("+")).join(" / ")

                        T.Label {
                            width: VLCStyle.dp(220, VLCStyle.scale)
                            anchors.verticalCenter: parent.verticalCenter

                            text: shortcut.modelData.label
                            color: VLCStyle.palette.fgA1
                            elide: Text.ElideRight
                            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                            font.weight: Font.Light
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: VLCStyle.dp(10, VLCStyle.scale)

                            Row {
                                visible: shortcut.modifiers.length > 0
                                spacing: VLCStyle.dp(4, VLCStyle.scale)

                                Repeater {
                                    model: shortcut.modifiers

                                    delegate: KeyCap {
                                        required property string modelData

                                        text: modelData
                                        narrow: true
                                    }
                                }
                            }

                            Repeater {
                                model: shortcut.keys

                                delegate: Row {
                                    id: alternative

                                    required property var modelData
                                    required property int index

                                    spacing: VLCStyle.dp(10, VLCStyle.scale)

                                    T.Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: alternative.index > 0

                                        text: "/"
                                        color: VLCStyle.palette.fgA1
                                        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                                        font.weight: Font.Light
                                    }

                                    Row {
                                        spacing: VLCStyle.dp(4, VLCStyle.scale)

                                        Repeater {
                                            model: alternative.modelData

                                            delegate: KeyCap {
                                                required property string modelData

                                                text: modelData
                                                narrow: shortcut.alternatives.length > 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    T.Label {
        x: VLCStyle.dp(62, VLCStyle.scale)
        y: VLCStyle.dp(671, VLCStyle.scale)
        height: VLCStyle.dp(28, VLCStyle.scale)

        verticalAlignment: Text.AlignVCenter

        text: qsTr("Find the full list in the menu.")
        color: VLCStyle.palette.fgA3
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }

    component KeyCap: Item {
        id: cap

        property alias text: label.text
        property bool narrow: false

        readonly property real _border: VLCStyle.dp(3, VLCStyle.scale)

        implicitWidth: label.implicitWidth
                       + 2 * (VLCStyle.dp(narrow ? 12 : 20, VLCStyle.scale) + _border)
        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)

        Rectangle {
            width: parent.width
            height: parent.height
            y: VLCStyle.dp(6, VLCStyle.scale)

            radius: VLCStyle.dp(12, VLCStyle.scale)
            color: Qt.rgba(0.36, 0.36, 0.36, 1)
            opacity: 0.25
        }

        Rectangle {
            anchors.fill: parent

            radius: VLCStyle.dp(12, VLCStyle.scale)
            color: VLCStyle.palette.bgA3
            border.width: cap._border
            border.color: VLCStyle.palette.dividerBright
        }

        T.Label {
            id: label

            anchors.centerIn: parent

            color: VLCStyle.palette.fg1
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Light
        }
    }
}
