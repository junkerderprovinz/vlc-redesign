import QtQuick

import VLC.MainInterface
import VLC.Style
import VLC.Util
import VLC.Menus

NavigableRow {
    id: root

    spacing: compact ? VLCStyle.margin_small : VLCStyle.dp(20, VLCStyle.scale)
    enabled: gridListBtn.visible || sortControl.visible || searchField.visible || searchToggle.visible

    property SortMenu sortMenu: null
    required property SortCtx sort
    required property SearchCtx search

    // In a narrow header the search field takes the place of the item count,
    // the row only keeps a button that opens it.
    property bool compact: false
    property bool searchOpen: false

    // Views beside the player always use the list.
    property bool gridMode: MainCtx.gridView && !MainCtx.playerView

    SortControl {
        id: sortControl

        anchors.verticalCenter: parent.verticalCenter

        visible: root.sort.available
        enabled: visible
        width: VLCStyle.icon_normal
        height: VLCStyle.icon_normal
        font.pixelSize: VLCStyle.icon_normal
        description: qsTr("Sort")

        model: root.sort.model

        menu: root.sortMenu

        sortKey:  root.sort.criteria
        sortOrder: root.sort.order

        onSortSelected: (key) => {
            root.sort.criteria = key
        }
        onSortOrderSelected: (type) => {
            root.sort.order = type
        }
    }

    //TODO: visible value of root.sort.available and MainCtx.hasGridListMode is initialised correctly but on first load still shows up
    IconToolButton {
        id: gridListBtn

        anchors.verticalCenter: parent.verticalCenter

        visible: MainCtx.hasGridListMode

        enabled: visible
        width: VLCStyle.icon_normal
        height: VLCStyle.icon_normal
        font.pixelSize: VLCStyle.icon_normal
        text: root.gridMode ? VLCIcons.grid : VLCIcons.list
        description: root.gridMode ? qsTr("Grid View") : qsTr("List View")
        onClicked: MainCtx.gridView = !MainCtx.gridView
    }

    SearchField {
        id: searchField

        anchors.verticalCenter: parent.verticalCenter

        visible: !root.compact && root.search.available

        width: Helpers.clamp(VLCStyle.appWidth * 0.17,
                             VLCStyle.dp(180, VLCStyle.scale),
                             VLCStyle.dp(325, VLCStyle.scale))

        search: root.search
    }

    IconToolButton {
        id: searchToggle

        anchors.verticalCenter: parent.verticalCenter

        visible: root.compact && root.search.available

        width: VLCStyle.icon_normal
        height: VLCStyle.icon_normal
        font.pixelSize: VLCStyle.icon_normal
        text: VLCIcons.search
        description: qsTr("Search")
        checked: root.searchOpen

        onClicked: root.searchOpen = !root.searchOpen
    }

    Connections {
        target: root.search

        function onAskShow() {
            if (root.compact)
                root.searchOpen = true
            else
                searchField.forceActiveFocus(Qt.ShortcutFocusReason)
        }
    }

    component SearchField: TextFieldExt {
        id: field

        required property SearchCtx search

        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

        leftPadding: VLCStyle.margin_xsmall + searchIcon.width + VLCStyle.dp(10, VLCStyle.scale)
        rightPadding: VLCStyle.margin_xsmall

        radius: VLCStyle.dp(6, VLCStyle.scale)

        font.pixelSize: VLCStyle.fontSize_large

        placeholderText: qsTr("Search")

        Accessible.name: qsTr("Search")

        background: Rectangle {
            radius: field.radius
            color: field.colorContext.bg.primary
            border.width: field.activeFocus ? VLCStyle.border : 0
            border.color: field.colorContext.accent
        }

        IconLabel {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.margin_xsmall
            anchors.verticalCenter: parent.verticalCenter

            text: VLCIcons.search
            color: field.colorContext.fg.secondary
            font.pixelSize: VLCStyle.icon_normal
        }

        Binding {
            target: field.search
            property: "pattern"
            value: field.text
            delayed: true
        }

        Keys.priority: Keys.AfterItem
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape && field.text.length > 0) {
                field.clear()
                event.accepted = true
                return
            }
            Navigation.defaultKeyAction(event)
        }
    }
}
