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
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

// The library beside the player: an icon rail and a narrow page of the
// current library section. It follows History like MainDisplay does, so
// leaving the player shows the same page in full.
FocusScope {
    id: root

    Accessible.role: Accessible.Pane
    Accessible.name: qsTr("Library Panel")
    AccessibleCompat.id: "libraryPanel"

    property real maximumWidth: Number.MAX_VALUE

    // The video shows through the panel.
    property bool overVideo: false

    readonly property real panelWidth: Math.round(Helpers.clamp(MainCtx.libraryPanel.width,
                                                                VLCStyle.dp(330, VLCStyle.scale),
                                                                Math.max(VLCStyle.dp(330, VLCStyle.scale),
                                                                         maximumWidth - rail.width)))

    implicitWidth: rail.width + panelWidth

    function loadCurrentHistoryView(focusReason) {
        stackView.loadView(History.viewPath, History.viewProp, focusReason)
    }

    Component.onCompleted: {
        // The window may start in the minimal or player view, before MainDisplay set a page.
        if (History.viewPath.length === 0)
            History.update(["home"])
        loadCurrentHistoryView(Qt.OtherFocusReason)
    }

    Connections {
        target: History
        function onNavigate(focusReason) {
            root.loadCurrentHistoryView(focusReason)
        }
    }

    Navigation.cancelAction: function() {
        MainCtx.libraryPanel.visible = false
    }

    Pages {
        id: pages
    }

    ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.View
    }

    SideNavigationPane {
        id: rail

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: implicitWidth

        compact: true
        card: false

        background: Rectangle {
            color: root.overVideo ? rail.colorContext.tokens.bgA3Glass : rail.colorContext.bg.secondary
        }

        pageLoader: stackView

        Navigation.parentItem: root
        Navigation.rightItem: stackView
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: rail.right

        width: root.panelWidth

        color: root.overVideo ? theme.tokens.bgB1Glass : theme.bg.primary
        clip: true

        Widgets.PageLoader {
            id: stackView

            anchors.fill: parent

            focus: true

            pageModel: pages.model

            Navigation.parentItem: root
            Navigation.leftItem: rail
        }
    }

    // MainDisplay and the library panel show the same pages.
    component Pages: QtObject {
        readonly property var model: [
            {
                name: "home",
                url: MainCtx.mediaLibraryAvailable ?
                     "qrc:///qt/qml/VLC/MediaLibrary/HomeDisplay.qml" :
                     "qrc:///qt/qml/VLC/MainInterface/NoMedialibHome.qml"
            }, {
                name: "video",
                url: "qrc:///qt/qml/VLC/MediaLibrary/VideoDisplay.qml"
            }, {
                name: "music",
                url: "qrc:///qt/qml/VLC/MediaLibrary/MusicDisplay.qml"
            }, {
                name: "network",
                url: "qrc:///qt/qml/VLC/Network/BrowseDisplay.qml"
            }, {
                name: "playlists",
                url: "qrc:///qt/qml/VLC/MediaLibrary/PlaylistsDisplay.qml"
            }, {
                name: "recent",
                url: "qrc:///qt/qml/VLC/MediaLibrary/RecentDisplay.qml"
            }, {
                name: "discover",
                url: "qrc:///qt/qml/VLC/Network/DiscoverDisplay.qml"
            }, {
                name: "mlsettings",
                url: "qrc:///qt/qml/VLC/MediaLibrary/MLFoldersSettings.qml"
            }
        ]
    }
}
