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

import VLC.MainInterface
import VLC.Dialogs
import VLC.Menus

StringListMenu {
    id: root

    ctx: MainCtx

    readonly property var _actions: [
        { text: qsTr("Open File..."), icon_svg: ":/icons/figma/file-duo.svg", trigger: () => DialogsProvider.simpleOpenDialog() },
        { text: qsTr("Open Multiple Files..."), icon_svg: ":/icons/figma/add.svg", trigger: () => DialogsProvider.openFileDialog() },
        { text: qsTr("Open Folder..."), icon_svg: ":/icons/figma/new-folder-duo.svg", trigger: () => DialogsProvider.PLOpenDir() },
        { text: qsTr("Open Disc..."), icon_svg: ":/icons/figma/disc-duo.svg", trigger: () => DialogsProvider.openDiscDialog() },
        { text: qsTr("Open Network Stream..."), icon_svg: ":/icons/figma/streaming-duo.svg", trigger: () => DialogsProvider.openNetDialog() },
        { text: qsTr("Open Capture Device..."), icon_svg: ":/icons/figma/capture-device-duo.svg", trigger: () => DialogsProvider.openCaptureDialog() }
    ]

    function show(item: Item) {
        popup(item.mapToGlobal(0, item.height),
              _actions.map((action) => ({ text: action.text, icon_svg: action.icon_svg })))
    }

    onSelected: (index) => _actions[index].trigger()
}
