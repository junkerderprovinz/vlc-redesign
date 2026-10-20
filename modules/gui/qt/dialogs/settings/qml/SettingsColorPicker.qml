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

T.Popup {
    id: root

    readonly property var t: SettingsTheme

    property real hue: 0
    property real saturation: 1
    property real brightness: 1

    readonly property color color: Qt.hsva(hue, saturation, brightness, 1)

    // emitted for every change, while the user is still picking
    signal picked(color color)

    function setColor(c) {
        const value = Qt.color(c)
        if (value.hsvHue >= 0)
            hue = value.hsvHue
        saturation = value.hsvSaturation
        brightness = value.hsvValue
    }

    function hex(c) {
        return Qt.color(c).toString().toUpperCase()
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    padding: t.dp(12)
    modal: false
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

    onColorChanged: {
        if (visible)
            picked(color)
    }

    background: Rectangle {
        radius: t.dp(6)
        color: t.bgA4

        Widgets.RoundedRectangleShadow {
            anchors.fill: parent
            z: -1
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, t.dark ? 0.35 : 0.15)
            yOffset: t.dp(4)
            blurRadius: t.dp(14)
        }
    }

    contentItem: Column {
        spacing: t.dp(10)

        // the popup lives in the window overlay, outside the dialog's colour context
        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        Rectangle {
            id: field

            width: t.dp(216)
            height: t.dp(150)
            radius: t.dp(4)
            color: Qt.hsva(root.hue, 1, 1, 1)

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }

            Rectangle {
                x: root.saturation * field.width - width / 2
                y: (1 - root.brightness) * field.height - height / 2
                width: t.dp(12)
                height: t.dp(12)
                radius: width / 2
                color: "transparent"
                border.width: t.dp(2)
                border.color: root.brightness > 0.5 ? "black" : "white"
            }

            MouseArea {
                anchors.fill: parent

                function pick(mouse) {
                    root.saturation = Math.max(0, Math.min(1, mouse.x / width))
                    root.brightness = 1 - Math.max(0, Math.min(1, mouse.y / height))
                }

                onPressed: (mouse) => pick(mouse)
                onPositionChanged: (mouse) => pick(mouse)
            }
        }

        Rectangle {
            id: hueBar

            width: field.width
            height: t.dp(14)
            radius: t.dp(4)

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0 / 6; color: "#ff0000" }
                GradientStop { position: 1 / 6; color: "#ffff00" }
                GradientStop { position: 2 / 6; color: "#00ff00" }
                GradientStop { position: 3 / 6; color: "#00ffff" }
                GradientStop { position: 4 / 6; color: "#0000ff" }
                GradientStop { position: 5 / 6; color: "#ff00ff" }
                GradientStop { position: 6 / 6; color: "#ff0000" }
            }

            Rectangle {
                x: root.hue * hueBar.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: t.dp(6)
                height: parent.height + t.dp(4)
                radius: t.dp(2)
                color: "white"
                border.width: t.dp(1)
                border.color: "black"
            }

            MouseArea {
                anchors.fill: parent

                function pick(mouse) {
                    root.hue = Math.max(0, Math.min(0.999, mouse.x / width))
                }

                onPressed: (mouse) => pick(mouse)
                onPositionChanged: (mouse) => pick(mouse)
            }
        }

        Row {
            spacing: t.dp(10)

            Rectangle {
                width: t.dp(32)
                height: t.dp(32)
                radius: t.dp(4)
                color: root.color
            }

            SettingsTextField {
                id: hexField

                width: field.width - t.dp(42)
                compact: true
                value: root.hex(root.color)

                onCommitted: (text) => {
                    const c = text.startsWith("#") ? text : "#" + text
                    if (/^#[0-9a-fA-F]{6}$/.test(c))
                        root.setColor(c)
                    else
                        hexField.text = hexField.value
                }
            }
        }
    }
}
