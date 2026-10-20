/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
import QtQuick.Window


import VLC.MainInterface
import VLC.Style

Row {
    id: windowButtonGroup

    spacing: 0
    padding: 0
    rightPadding: VLCStyle.titleBar_padding

    width: implicitWidth

    property color color: theme.fg.primary
    property color hoverColor: theme.palette.bgA1

    readonly property bool buttonHovered: {
        let h = false
        for (let i = 0; i < repeater.count; ++i)
            h = h || repeater.itemAt(i).hovered

        return h
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Repeater {
        id: repeater

        model: MainCtx.csdButtonModel.windowCSDButtons

        Row {
            id: entry

            required property var modelData

            readonly property bool hovered: button.hovered || button.showHovered || fullscreenButton.hovered

            height: windowButtonGroup.height

            // the fullscreen toggle sits right before the close button
            CSDWindowButton {
                id: fullscreenButton

                visible: entry.modelData.type === CSDButton.Close

                height: entry.height

                color: windowButtonGroup.color

                hoverColor: windowButtonGroup.hoverColor

                isThemeDark: theme.tokens.isDark

                iconTxt: (MainCtx.intfMainWindow.visibility === Window.FullScreen)
                         ? VLCIcons.defullscreen
                         : VLCIcons.fullscreen

                onClicked: MainCtx.toggleInterfaceFullScreen()
            }

            CSDWindowButton {
                id: button

                height: entry.height

                showHovered: entry.modelData.showHovered

                externalPressed: entry.modelData.externalPressed

                color: windowButtonGroup.color

                hoverColor: windowButtonGroup.hoverColor

                isThemeDark: theme.tokens.isDark

                iconTxt:{
                    switch (entry.modelData.type) {
                    case CSDButton.Minimize:
                        return VLCIcons.window_minimize

                    case CSDButton.MaximizeRestore:
                        return (MainCtx.intfMainWindow.visibility === Window.Maximized)
                                ? VLCIcons.window_restore
                                : VLCIcons.window_maximize

                    case CSDButton.Close:
                        return VLCIcons.window_close
                    }
                    console.assert(false, "unreachable")
                }

                onClicked: entry.modelData.click()

                // handles VLCStyle.scale changes
                onWidthChanged: Qt.callLater(updateRect)
                onHeightChanged: Qt.callLater(updateRect)

                Connections {
                    target: VLCStyle

                    // handle window resize
                    function onAppWidthChanged() { Qt.callLater(button.updateRect) }
                    function onAppHeightChanged() { Qt.callLater(button.updateRect) }
                }

                function updateRect() {
                    const point = mapToItem(null, 0, 0)
                    const rect = Qt.rect(point.x, point.y, width, height)

                    entry.modelData.rect = rect
                }

                // register this button on the C++ side so WM_NCHITTEST can
                // find it; unregistration happens automatically when the item
                // is destroyed
                Component.onCompleted: entry.modelData.registerItem(button)
            }
        }
    }
}
