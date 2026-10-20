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

// A row (or column) of exclusive options of equal size.
//
// model is an array of strings or of objects with a `text` and an optional
// `trailing` component shown after the text.
T.Control {
    id: root

    // Properties

    property alias model: repeater.model

    property int currentIndex: -1

    property int orientation: Qt.Horizontal

    readonly property bool horizontal: (orientation === Qt.Horizontal)

    property real segmentHeight: horizontal ? VLCStyle.dp(40, VLCStyle.scale)
                                            : VLCStyle.dp(36, VLCStyle.scale)

    readonly property alias count: repeater.count

    // Signals

    signal activated(int index)

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_xxxsmall
    spacing: VLCStyle.margin_xxxsmall

    onActiveFocusChanged: {
        if (activeFocus)
            contentItem.forceActiveFocus(focusReason)
    }

    // Functions

    function itemAt(index) {
        return repeater.itemAt(index)
    }

    // Private

    readonly property real _segmentImplicitWidth: {
        let width = 0
        for (let i = 0; i < repeater.count; ++i) {
            const item = repeater.itemAt(i)
            if (item)
                width = Math.max(width, item.implicitWidth)
        }
        return width
    }

    readonly property real _segmentWidth: horizontal && count > 0
                                          ? (availableWidth - spacing * (count - 1)) / count
                                          : availableWidth

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Switch

        enabled: root.enabled
    }

    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)

        color: theme.bg.primary
    }

    contentItem: FocusScope {
        focus: true

        implicitWidth: root.horizontal
                       ? root._segmentImplicitWidth * root.count + root.spacing * Math.max(root.count - 1, 0)
                       : root._segmentImplicitWidth
        implicitHeight: grid.implicitHeight

        Grid {
            id: grid

            columns: root.horizontal ? Math.max(root.count, 1) : 1

            spacing: root.spacing

            Repeater {
                id: repeater

                delegate: SegmentButton {
                    required property var modelData
                    required property int index

                    width: root._segmentWidth
                    height: root.segmentHeight

                    text: (typeof modelData === "string") ? modelData : (modelData?.text ?? "")
                    trailing: (typeof modelData === "object") ? (modelData?.trailing ?? null) : null

                    horizontalAlignment: root.horizontal ? Text.AlignHCenter : Text.AlignLeft

                    checkable: false
                    checked: (index === root.currentIndex)

                    focus: (index === Math.max(root.currentIndex, 0))

                    Navigation.parentItem: root
                    Navigation.leftItem: root.horizontal && index > 0 ? root.itemAt(index - 1) : null
                    Navigation.rightItem: root.horizontal ? root.itemAt(index + 1) : null
                    Navigation.upItem: !root.horizontal && index > 0 ? root.itemAt(index - 1) : null
                    Navigation.downItem: !root.horizontal ? root.itemAt(index + 1) : null

                    onClicked: {
                        if (root.currentIndex === index)
                            return
                        root.currentIndex = index
                        root.activated(index)
                    }
                }
            }
        }
    }
}
