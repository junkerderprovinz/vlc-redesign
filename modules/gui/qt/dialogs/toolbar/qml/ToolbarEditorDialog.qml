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
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.PlayerControls


T.Popup {
    id: root

    parent: T.Overlay.overlay

    x: 0
    y: 0
    width: parent?.width ?? 0
    height: parent?.height ?? 0

    padding: 0

    modal: true
    dim: false
    focus: true

    closePolicy: T.Popup.NoAutoClose

    signal unload()

    onAboutToShow: {
        // Save first, in case the dialog is rejected.
        MainCtx.controlbarProfileModel.save(false)

        toolbarEditor.openedProfile = MainCtx.controlbarProfileModel.selectedProfile
        toolbarEditor.identifier = (MainCtx.playerView && !MainCtx.hasEmbededVideo) ? PlayerControlbarModel.Audioplayer
                                                                                   : PlayerControlbarModel.Videoplayer
    }

    background: null

    contentItem: ToolbarEditor {
        id: toolbarEditor

        focus: true

        onAccepted: {
            MainCtx.controlbarProfileModel.save()
            root.close()
            root.unload()
        }

        onRejected: {
            // Load saved to discard the changes
            MainCtx.controlbarProfileModel.reload()
            root.close()
            root.unload()
        }
    }
}
