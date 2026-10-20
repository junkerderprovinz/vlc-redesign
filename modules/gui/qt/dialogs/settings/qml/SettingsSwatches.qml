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

import VLC.Dialogs

// A row of color swatches; `swatches` holds { color, text } entries, an entry
// without a color is drawn as a rainbow and stands for "any other color".
Rectangle {
    id: root

    readonly property var t: SettingsTheme

    property var swatches: []
    property int currentIndex: -1

    signal activated(int index)

    function itemAt(index) {
        return repeater.itemAt(index)
    }

    implicitWidth: t.controlWidth
    implicitHeight: t.dp(36)

    radius: t.dp(6)
    color: t.bgB2

    Row {
        id: row

        anchors.fill: parent
        anchors.margins: t.dp(2)
        spacing: t.dp(4)

        Repeater {
            id: repeater

            model: root.swatches

            delegate: T.AbstractButton {
                id: swatch

                required property int index
                required property var modelData

                readonly property bool selected: index === root.currentIndex

                width: (row.width - row.spacing * (root.swatches.length - 1)) / root.swatches.length
                height: row.height
                focusPolicy: Qt.StrongFocus
                text: modelData.text

                Accessible.role: Accessible.RadioButton
                Accessible.checked: selected
                Accessible.name: text

                onClicked: root.activated(index)

                background: Rectangle {
                    radius: t.dp(4)
                    color: swatch.selected ? t.accentBgBright : (swatch.hovered ? t.bgA4 : "transparent")
                    border.width: swatch.visualFocus ? t.dp(1) : 0
                    border.color: t.accentDim
                }

                contentItem: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        width: t.dp(20)
                        height: t.dp(20)
                        radius: t.dp(1)
                        opacity: swatch.selected ? 1 : 0.7
                        color: swatch.modelData.color ?? "transparent"
                        gradient: swatch.modelData.color ? null : rainbow

                        Gradient {
                            id: rainbow

                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#e15032" }
                            GradientStop { position: 0.25; color: "#c49e23" }
                            GradientStop { position: 0.5; color: "#19a234" }
                            GradientStop { position: 0.75; color: "#185dd3" }
                            GradientStop { position: 1.0; color: "#f052b3" }
                        }
                    }
                }
            }
        }
    }
}
