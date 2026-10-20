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

import VLC.Style

// One of the left, center and right groups of the edited control bar. Drops
// anywhere in its part of the row land at the nearer end of the group.
Item {
    id: zone

    property alias view: dndView

    // Horizontal extent of the row that belongs to this group, in the
    // coordinates of the parent.
    property real regionStart: 0
    property real regionEnd: 0

    readonly property bool highlighted: regionDropArea.containsDrag || dndView.containsDrag

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    DropArea {
        id: regionDropArea

        x: zone.regionStart - zone.x
        width: zone.regionEnd - zone.regionStart
        height: parent.height

        onDropped: (drop) => {
            let destIndex = (drop.x + regionDropArea.x < dndView.x) ? 0 : dndView.count

            if (drop.source.dndView === dndView && destIndex === dndView.count)
                --destIndex

            dndView.dropEvent(drop, Math.max(0, destIndex))
        }
    }

    EditorDashedFrame {
        anchors.fill: dndView
        anchors.margins: -VLCStyle.margin_xxxsmall

        visible: zone.highlighted || (root.dragActive && dndView.count === 0)
        color: zone.highlighted ? theme.palette.accent : theme.palette.fgA3
    }

    EditorDNDView {
        id: dndView

        anchors.fill: parent
        anchors.topMargin: VLCStyle.margin_xxsmall
        anchors.bottomMargin: VLCStyle.margin_xxsmall

        onContainsDragChanged: {
            if (containsDrag)
                root._viewThatContainsDrag = this
            else if (root._viewThatContainsDrag === this)
                root._viewThatContainsDrag = null
        }
    }
}
