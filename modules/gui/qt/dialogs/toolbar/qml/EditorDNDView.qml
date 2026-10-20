/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import QtQml.Models


import VLC.Style
import VLC.Util
import VLC.PlayerControls

ListView {
    id: playerBtnDND

    spacing: VLCStyle.margin_xsmall
    orientation: Qt.Horizontal
    interactive: false

    implicitWidth: contentWidth

    currentIndex: -1
    highlightFollowsCurrentItem: false
    boundsBehavior: Flickable.StopAtBounds

    property bool containsDrag: false

    // Width the view may take; stretching controls such as the seek bar
    // share what the other controls leave of it.
    property real availableWidth: -1

    readonly property real stretchWidth: {
        if (availableWidth < 0)
            return VLCStyle.dp(160, VLCStyle.scale)

        // Delegates are created after the count changes.
        if (contentItem.children.length === 0)
            return 0

        let fixed = 0
        let stretching = 0
        for (let i = 0; i < count; ++i) {
            const item = itemAtIndex(i)
            if (!item)
                continue
            if (item.stretches)
                ++stretching
            else
                fixed += item.implicitWidth
        }

        if (stretching === 0)
            return 0

        return (availableWidth - fixed - spacing * Math.max(0, count - 1)) / stretching
    }

    function isStretching(controlId) {
        return controlId === ControlListModel.POSITION_WIDGET
                || controlId === ControlListModel.WIDGET_SPACER_EXTEND
    }

    remove: Transition {
        OpacityAnimator {
            from: 1.0
            to: 0.0

            duration: VLCStyle.duration_long
        }
    }

    function dropEvent(drag, destIndex) {
        if (drag.source.dndView === playerBtnDND) {
            // moving from same section
            playerBtnDND.model.move(drag.source.DelegateModel.itemsIndex,
                                    destIndex)
            drag.source.visible = true
            drag.accept(Qt.MoveAction)
        } else if (drag.source.objectName === "buttonsList") {
            // moving from buttonsList
            playerBtnDND.model.insert(destIndex, {"id" : drag.source.mIndex})
            drag.accept(Qt.CopyAction)
        } else {
            // moving between sections or views
            playerBtnDND.model.insert(destIndex, {"id" : drag.source.controlId})
            drag.source.dndView.model.remove(drag.source.DelegateModel.itemsIndex)
            drag.accept(Qt.MoveAction)
        }
    }

    MouseArea {
        anchors.fill: parent

        preventStealing: true

        z: -1

        cursorShape: root.dragActive ? Qt.DragMoveCursor : Qt.ArrowCursor
    }

    delegate: EditorDNDDelegate {
        id: dndDelegate

        readonly property bool stretches: playerBtnDND.isStretching(controlId)

        width: stretches ? Math.max(VLCStyle.dp(80, VLCStyle.scale), playerBtnDND.stretchWidth)
                         : implicitWidth
        height: (contentItem.implicitHeight > 0) ? Math.min(implicitHeight, playerBtnDND.height)
                                                 : playerBtnDND.height

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        dndView: playerBtnDND

        Binding {
            when: dndDelegate.dropArea.containsDrag
            value: true

            target: playerBtnDND
            property: "containsDrag"
        }
    }
}
