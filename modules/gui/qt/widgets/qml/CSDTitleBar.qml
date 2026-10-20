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
import VLC.Util
import VLC.Widgets as Widgets

// window title bar with the cone, the centered title and the window buttons
T.Pane {
    id: root

    property string title: MainCtx.intfMainWindow ? MainCtx.intfMainWindow.title : ""

    // items shown after the cone, such as a menu button
    default property alias leftContent: leftRow.data

    readonly property bool buttonHovered: csdButtons.item ? csdButtons.item.buttonHovered : false

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    implicitHeight: VLCStyle.titleBar_height

    padding: 0

    background: Rectangle {
        color: theme.bg.primary
    }

    Loader {
        anchors.fill: parent
        active: MainCtx.clientSideDecoration
        sourceComponent: Widgets.CSDTitlebarTapNDrapHandler { }
    }

    Row {
        id: leftRow

        anchors.left: parent.left
        anchors.leftMargin: VLCStyle.titleBar_padding
        anchors.verticalCenter: parent.verticalCenter

        spacing: VLCStyle.dp(7, VLCStyle.scale)

        Item {
            implicitWidth: VLCStyle.dp(38, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

            Image {
                anchors.centerIn: parent

                width: VLCStyle.icon_normal
                height: VLCStyle.icon_normal

                sourceSize: Qt.size(width, height)
                source: SVGColorImage.colorize("qrc:///icons/figma/vlc.svg")
                                     .accent(theme.palette.accentLogo)
                                     .uri()
            }
        }
    }

    Widgets.LabelExt {
        anchors.centerIn: parent

        width: Math.min(implicitWidth,
                        root.width - 2 * Math.max(leftRow.width + leftRow.anchors.leftMargin,
                                                  csdButtons.width))

        text: root.title
        textFormat: Text.PlainText

        color: theme.fg.primary
        font.pixelSize: VLCStyle.fontSize_normal

        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Loader {
        id: csdButtons

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        active: MainCtx.clientSideDecoration
        source: VLCStyle.palette.hasCSDImage
                ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
                : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
    }
}
