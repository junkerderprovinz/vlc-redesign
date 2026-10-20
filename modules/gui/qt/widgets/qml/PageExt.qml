/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Menus
import VLC.Util
import VLC.Dialogs

T.Page {
    id: root

    //path of the current page loader
    property var pagePrefix: []

    //note that T.Page introduce an intermediate Item, so to access our delegate,
    //we need to use contentChildren[0] rather than contentItem
    readonly property Item _firstChild: contentChildren[0] ?? null

    //indicates whether the subview support grid/list mode
    property bool hasGridListMode: _firstChild?.hasGridListMode ?? false

    property bool isSearchable: _firstChild?.isSearchable ?? false

    property var sortModel: _firstChild?.sortModel ?? null

    //property is *not* readOnly, a PageLoader may define a localMenuDelegate common for its subviews (music, video)
    property SortMenu sortMenu: null

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    property bool enableBeginningFade: true
    property bool enableEndFade: true

    //number of items shown in the header, negative when the view does not tell
    property int count: _firstChild?.count ?? -1

    //list of { text, path } from the library section down to this page
    readonly property var breadcrumbs: {
        const crumbs = []
        const add = (text, path) => {
            if (text && !crumbs.some((crumb) => crumb.text === text))
                crumbs.push({ text: text, path: path })
        }

        if (pagePrefix.length > 0)
            add(_sectionTitle(pagePrefix[0]), [pagePrefix[0]])

        add(root.title, pagePrefix)

        if (History.exactMatch(History.viewPath, pagePrefix))
            add(History.viewProp?.title, pagePrefix)

        return crumbs
    }

    readonly property SearchCtx search: _searchCtx
    readonly property SortCtx sort: _sortCtx


    SearchCtx {
        id: _searchCtx
        available: root.isSearchable
    }

    SortCtx {
        id: _sortCtx

        readonly property string _sortCriteriaKey: ["sortCriteria", ...root.pagePrefix].join("/")
        readonly property string _sortOrderKey:  ["sortOrder", ...root.pagePrefix].join("/")

        available: Helpers.isArray(root.sortModel) && (root.sortModel).length > 0
        model: root.sortModel

        //save & restore setting of the page
        Component.onCompleted: {
            const criteria = MainCtx.settingValue(_sortCriteriaKey, undefined)
            if (criteria !== undefined)
                _sortCtx.criteria = criteria

            const order = MainCtx.settingValue(_sortOrderKey, undefined)
            if (order !== undefined)
                _sortCtx.order = parseInt(order)
        }

        Component.onDestruction: {
            MainCtx.setSettingValue(_sortCriteriaKey, _sortCtx.criteria)
            MainCtx.setSettingValue(_sortOrderKey, _sortCtx.order)
        }
    }

    Binding {
        target: MainCtx
        property: "hasGridListMode";
        value: root.hasGridListMode
    }

    Connections {
        target: MainCtx.search
        enabled: root.visible && root.isSearchable

        function onAskShow() {
            _searchCtx.askShow()
        }
    }

    on_FirstChildChanged: {
        if (!_firstChild)
            return
        _firstChild.Navigation.parentItem = root
        _firstChild.Navigation.upItem = root.header
    }

    function positionContentAtBeginning() {
        _firstChild?.positionContentAtBeginning?.()
    }

    function _sectionTitle(name) {
        switch (name) {
        case "home":
            return qsTr("Home")
        case "video":
            return qsTr("Videos")
        case "music":
            return qsTr("Music")
        case "network":
            return qsTr("Network")
        case "playlists":
            return qsTr("Playlists")
        case "recent":
            return qsTr("Recent")
        case "discover":
            return qsTr("Discover")
        default:
            return ""
        }
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    header: DefaultPageHeader {
        text: root.title

        breadcrumbs: root.breadcrumbs
        count: root.count

        leftPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_left_margin + root.leftPadding
        rightPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_right_margin + root.rightPadding

        sortMenu: root.sortMenu

        search: _searchCtx
        sort: _sortCtx

        Navigation.parentItem: root
        Navigation.downAction: function() {
            if (typeof root.setCurrentItemFocus === "function")
                root.setCurrentItemFocus(Qt.TabFocusReason)
            else if (typeof root._firstChild?.setCurrentItemFocus === "function")
             root._firstChild.setCurrentItemFocus(Qt.TabFocusReason)
            else if (root._firstChild)
                root._firstChild.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    component DefaultPageHeader: T.ToolBar {
        id: defaultPageHeader

        // Properties

        // Shown when no breadcrumbs are given.
        property string text

        property var breadcrumbs: []

        property int count: -1

        property alias sortMenu: gridSortFilter.sortMenu

        property alias search: gridSortFilter.search
        property alias sort: gridSortFilter.sort

        // The library panel beside the player is too narrow for one row.
        readonly property bool compact: width < VLCStyle.dp(640, VLCStyle.scale)

        readonly property var _crumbs: (breadcrumbs.length > 0) ? breadcrumbs
                                                                : [{ text: defaultPageHeader.text, path: [] }]

        position: T.ToolBar.Header

        topPadding: VLCStyle.dp(20, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(17, VLCStyle.scale) + VLCStyle.border

        // FIXME: `GridItem`'s background extends beyond its
        //        bounding rect, violating the hypothetical
        //        clip test (see 7e6b23db).
        bottomInset: (MainCtx.hasGridListMode && MainCtx.gridView) ? VLCStyle.gridItemSelectedBorder : undefined

        // Settings

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        // Children

        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: ColorContext.View
        }

        AddMediaMenu {
            id: addMediaMenu
        }

        StringListMenu {
            id: moreMenu

            ctx: MainCtx

            readonly property var _actions: [
                { text: qsTr("Add Folder to Play Queue..."), trigger: () => DialogsProvider.PLAppendDir() },
                { text: qsTr("Preferences..."), trigger: () => DialogsProvider.prefsDialog() }
            ]

            function show(item) {
                popup(item.mapToGlobal(0, item.height), _actions.map((action) => action.text))
            }

            onSelected: (index) => _actions[index].trigger()
        }

        StringListMenu {
            id: hiddenCrumbsMenu

            ctx: MainCtx

            function show(item) {
                popup(item.mapToGlobal(0, item.height),
                      breadcrumbRow.hiddenCrumbs.map((crumb) => crumb.text))
            }

            onSelected: (index) => History.push(breadcrumbRow.hiddenCrumbs[index].path)
        }

        background: Rectangle {
            color: theme.bg.primary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: defaultPageHeader.leftPadding
                anchors.rightMargin: defaultPageHeader.rightPadding
                anchors.bottomMargin: -defaultPageHeader.bottomInset

                height: VLCStyle.border
                color: theme.separator
            }
        }

        contentItem: ColumnLayout {
            spacing: VLCStyle.dp(20, VLCStyle.scale)

            RowLayout {
                id: firstRow

                Layout.fillWidth: true
                Layout.minimumHeight: defaultPageHeader.compact ? VLCStyle.icon_normal
                                                                : VLCStyle.dp(34, VLCStyle.scale)

                spacing: defaultPageHeader.compact ? VLCStyle.dp(10, VLCStyle.scale)
                                                   : VLCStyle.dp(20, VLCStyle.scale)

                Row {
                    spacing: VLCStyle.margin_small

                    HeaderButton {
                        id: backButton

                        text: VLCIcons.back
                        description: qsTr("Back")
                        enabled: !History.previousEmpty

                        onClicked: History.previous(Qt.MouseFocusReason)
                    }

                    HeaderButton {
                        text: VLCIcons.arrow_right
                        description: qsTr("Forward")
                        enabled: !History.nextEmpty

                        onClicked: History.next(Qt.MouseFocusReason)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: breadcrumbRow.width > width

                    Row {
                        id: breadcrumbRow

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: VLCStyle.dp(6, VLCStyle.scale)

                        // The narrow header keeps the last two folders and hides the rest behind "...".
                        readonly property int hiddenCount: (defaultPageHeader.compact && defaultPageHeader._crumbs.length > 2)
                                                           ? defaultPageHeader._crumbs.length - 2 : 0
                        readonly property var hiddenCrumbs: defaultPageHeader._crumbs.slice(0, hiddenCount)
                        readonly property var shownCrumbs: defaultPageHeader._crumbs.slice(hiddenCount)

                        CrumbButton {
                            id: hiddenCrumbsButton

                            visible: breadcrumbRow.hiddenCount > 0

                            text: "..."
                            Accessible.name: qsTr("Show parent folders")

                            onClicked: hiddenCrumbsMenu.show(hiddenCrumbsButton)
                        }

                        CrumbSeparator {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: hiddenCrumbsButton.visible
                        }

                        Repeater {
                            model: breadcrumbRow.shownCrumbs

                            delegate: Row {
                                required property var modelData
                                required property int index

                                readonly property bool isLast: (index === breadcrumbRow.shownCrumbs.length - 1)

                                spacing: breadcrumbRow.spacing

                                CrumbSeparator {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: index > 0
                                }

                                CrumbButton {
                                    text: modelData.text
                                    emphasized: isLast && !defaultPageHeader.compact

                                    onClicked: {
                                        if (!isLast && modelData.path.length > 0)
                                            History.push(modelData.path)
                                    }
                                }
                            }
                        }
                    }
                }

                T.Label {
                    visible: !defaultPageHeader.compact && defaultPageHeader.count >= 0

                    text: qsTr("%1 item", "%1 items", defaultPageHeader.count).arg(defaultPageHeader.count)
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_large
                }

                Item {
                    id: wideControlsSlot

                    visible: !defaultPageHeader.compact

                    implicitWidth: gridSortFilter.implicitWidth
                    implicitHeight: gridSortFilter.implicitHeight
                }

                Row {
                    spacing: VLCStyle.margin_small

                    HeaderButton {
                        id: addButton

                        visible: !defaultPageHeader.compact

                        text: VLCIcons.add
                        description: qsTr("Add")

                        onClicked: addMediaMenu.show(addButton)
                    }

                    HeaderButton {
                        id: moreButton

                        text: VLCIcons.more
                        description: qsTr("More")

                        onClicked: moreMenu.show(moreButton)
                    }

                    HeaderButton {
                        visible: defaultPageHeader.compact && MainCtx.playerView

                        text: VLCIcons.open
                        description: qsTr("Open full library")

                        onClicked: MainCtx.playerView = false
                    }
                }
            }

            RowLayout {
                id: secondRow

                Layout.fillWidth: true
                Layout.minimumHeight: VLCStyle.icon_normal

                visible: defaultPageHeader.compact

                spacing: VLCStyle.dp(10, VLCStyle.scale)

                T.Label {
                    Layout.fillWidth: true

                    visible: !gridSortFilter.searchOpen

                    text: (defaultPageHeader.count >= 0)
                          ? qsTr("%1 item", "%1 items", defaultPageHeader.count).arg(defaultPageHeader.count)
                          : ""
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_large
                }

                GridSortFilterControls.SearchField {
                    id: compactSearchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)

                    visible: gridSortFilter.searchOpen

                    search: gridSortFilter.search

                    onVisibleChanged: {
                        if (visible)
                            forceActiveFocus(Qt.ShortcutFocusReason)
                    }

                    Keys.onEscapePressed: {
                        clear()
                        gridSortFilter.searchOpen = false
                    }
                }

                Item {
                    id: compactControlsSlot

                    implicitWidth: gridSortFilter.implicitWidth
                    implicitHeight: gridSortFilter.implicitHeight
                }
            }

            GridSortFilterControls {
                id: gridSortFilter

                parent: defaultPageHeader.compact ? compactControlsSlot : wideControlsSlot
                anchors.verticalCenter: parent.verticalCenter

                compact: defaultPageHeader.compact

                focus: true
                Navigation.parentItem: defaultPageHeader
            }
        }

    }

    component HeaderButton: IconToolButton {
        width: VLCStyle.icon_normal
        height: VLCStyle.icon_normal

        font.pixelSize: VLCStyle.icon_normal
    }

    component CrumbSeparator: T.Label {
        ColorContext {
            id: separatorTheme
            colorSet: ColorContext.View
        }

        text: "▶"
        color: separatorTheme.fg.secondary
        opacity: 0.5
        font.pixelSize: VLCStyle.fontSize_xsmall
    }

    component CrumbButton: T.AbstractButton {
        id: crumb

        // The page the header belongs to, set in bold when there is room.
        property bool emphasized: false

        implicitWidth: crumbLabel.implicitWidth
        implicitHeight: crumbLabel.implicitHeight

        Accessible.name: text
        Accessible.onPressAction: crumb.clicked()

        ColorContext {
            id: crumbTheme
            colorSet: ColorContext.View
        }

        contentItem: T.Label {
            id: crumbLabel

            text: crumb.text
            elide: Text.ElideRight

            color: (crumb.hovered || crumb.emphasized) ? crumbTheme.fg.primary : crumbTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_xlarge
            font.weight: crumb.emphasized ? Font.DemiBold : Font.Normal
        }
    }
}
