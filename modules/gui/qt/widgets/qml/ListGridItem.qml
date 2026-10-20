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
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

// A compact media row: a small thumbnail followed by the name. It has the
// same signals as GridItem so both can be used as delegates of the same views.
T.ItemDelegate {
    id: root

    // Properties

    property Item view: null

    property Item dragItem: null

    property bool selected: false

    // played items are drawn dimmer
    property bool dimmed: false

    // the item is the media being played
    property bool current: false

    // 0 to 1, a bar is drawn below the thumbnail when it is greater than 0
    property real progress: 0

    property url image
    property string fallbackImage

    // glyph drawn instead of a picture, for folders, playlists and actions
    property string iconText: ""

    property alias title: titleLabel.text

    property bool showContextButton: true

    property int _modifiersOnLastPress: Qt.NoModifier

    // Signals

    signal playClicked
    signal itemClicked(int modifier, bool select)
    signal itemDoubleClicked(int modifier)
    signal contextMenuButtonClicked(Item menuParent, point globalMousePos)

    // Settings

    implicitWidth: VLCStyle.dp(360, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

    spacing: VLCStyle.dp(10, VLCStyle.scale)

    highlighted: (hovered || visualFocus)

    Accessible.role: Accessible.Cell
    Accessible.name: title
    Accessible.selected: root.selected
    Accessible.onPressAction: root.playClicked()

    Keys.onMenuPressed: root.contextMenuButtonClicked(thumbnail, root.mapToGlobal(0, root.height))

    Component.onCompleted: {
        // Unset the cursor of the AbstractButton so that the busy cursor
        // of the view stays visible over the delegate:
        MainCtx.unsetCursor(this)
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Item

        focused: root.visualFocus
        hovered: root.hovered
    }

    // TODO: Qt bug 6.2: QTBUG-103604
    DoubleClickIgnoringItem {
        anchors.fill: parent

        DragHandler {
            acceptedDevices: PointerDevice.AllDevices & ~(PointerDevice.TouchScreen)

            target: null

            grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType | PointerHandler.ApprovesTakeOverByAnything

            onActiveChanged: {
                if (!root.dragItem)
                    return

                if (active && !root.selected)
                    root.itemClicked(root._modifiersOnLastPress, true)

                if (active)
                    root.dragItem.Drag.active = true
                else
                    root.dragItem.Drag.drop()
            }
        }

        TapHandler {
            acceptedDevices: PointerDevice.AllDevices & ~(PointerDevice.TouchScreen)

            acceptedButtons: Qt.RightButton | Qt.LeftButton

            grabPermissions: TapHandler.CanTakeOverFromHandlersOfDifferentType | TapHandler.ApprovesTakeOverByAnything

            gesturePolicy: TapHandler.ReleaseWithinBounds

            onSingleTapped: (eventPoint, button) => {
                initialAction()

                if (button === Qt.RightButton)
                    root.contextMenuButtonClicked(thumbnail, eventPoint.globalPosition)
                else
                    root.itemClicked(point.modifiers, true)
            }

            onDoubleTapped: (eventPoint, button) => {
                if (button === Qt.LeftButton)
                    root.itemDoubleClicked(point.modifiers)
            }

            Component.onCompleted: {
                canceled.connect(initialAction)
            }

            function initialAction() {
                root._modifiersOnLastPress = point.modifiers

                root.forceActiveFocus(Qt.MouseFocusReason)
            }
        }

        DelegateTouchTapHandler {
            delegate: root

            onSingleTapped: (eventPoint, button) => {
                root.itemClicked(Qt.NoModifier, false)
                root.itemDoubleClicked(Qt.NoModifier)
            }

            onDoubleTapped: (eventPoint, button) => {
                root.playClicked()
            }

            onContextMenuRequested: (index, globalPoint) => {
                root.contextMenuButtonClicked(thumbnail, globalPoint)
            }
        }
    }

    background: AnimatedBackground {
        enabled: theme.initialized

        radius: VLCStyle.dp(4, VLCStyle.scale)

        color: root.selected ? theme.bg.highlight : theme.bg.primary
        border.color: root.visualFocus ? theme.visualFocus : Qt.alpha(theme.visualFocus, 0.0)
    }

    contentItem: RowLayout {
        // Keep the content above the handlers of the control:
        z: 1

        spacing: root.spacing

        Item {
            id: thumbnail

            Layout.preferredWidth: root.height
            Layout.preferredHeight: root.height

            readonly property bool hasPicture: root.iconText === ""

            Rectangle {
                anchors.fill: parent

                visible: thumbnail.hasPicture

                radius: VLCStyle.dp(2, VLCStyle.scale)
                color: theme.bg.secondary
            }

            Widgets.ImageExt {
                id: picture

                anchors.fill: parent

                visible: thumbnail.hasPicture && source.toString() !== ""

                radius: VLCStyle.dp(2, VLCStyle.scale)

                source: {
                    if (!thumbnail.hasPicture)
                        return ""
                    if (root.image.toString() !== "")
                        return root.image
                    return root.fallbackImage
                }

                readonly property real eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

                sourceSize: Qt.size(width * eDPR, height * eDPR)

                fillMode: Image.PreserveAspectCrop
            }

            Widgets.IconLabel {
                anchors.centerIn: parent

                visible: !thumbnail.hasPicture

                text: root.iconText
                color: root.current ? theme.accent : theme.fg.primary
            }

            Rectangle {
                anchors.fill: parent

                visible: root.current && thumbnail.hasPicture

                radius: VLCStyle.dp(2, VLCStyle.scale)
                color: Qt.rgba(theme.accent.r * 0.26, theme.accent.g * 0.26, theme.accent.b * 0.26, 1)

                Widgets.IconLabel {
                    anchors.centerIn: parent

                    text: VLCIcons.play
                    color: theme.accent
                    font.pixelSize: VLCStyle.icon_normal
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom

                visible: root.progress > 0 && thumbnail.hasPicture

                width: parent.width * Helpers.clamp(root.progress, 0, 1)
                height: VLCStyle.dp(3, VLCStyle.scale)

                color: theme.accent
            }
        }

        Widgets.ListLabel {
            id: titleLabel

            Layout.fillWidth: true
            Layout.fillHeight: true

            font.pixelSize: VLCStyle.fontSize_normal
            font.weight: Font.Normal

            color: {
                if (root.current)
                    return theme.accent
                if (root.selected)
                    return theme.fg.highlight
                if (root.dimmed && !root.highlighted)
                    return theme.fg.secondary
                return theme.fg.primary
            }
        }

        Widgets.IconToolButton {
            id: contextButton

            Layout.preferredWidth: implicitWidth

            visible: root.showContextButton
            opacity: (root.highlighted || activeFocus) ? 1 : 0

            description: qsTr("More options")
            text: VLCIcons.more

            onClicked: root.contextMenuButtonClicked(contextButton, contextButton.mapToGlobal(0, contextButton.height))
        }
    }
}
