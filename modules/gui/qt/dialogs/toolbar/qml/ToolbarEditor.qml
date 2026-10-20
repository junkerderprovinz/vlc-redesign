/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQml.Models


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Dialogs
import VLC.Player
import VLC.PlayerControls

// The palette of controls in a dialog over the dimmed player, and an editable
// copy of the control bar laid over the real one at the bottom of the window.
FocusScope {
    id: root

    property int identifier: PlayerControlbarModel.Videoplayer

    // Selected profile when the editor was opened, so that switching to
    // another profile can be saved too.
    property int openedProfile: -1

    property bool dragActive: !!_viewThatContainsDrag || buttonDragItem.Drag.active

    property bool removeInfoRectVisible: false

    property EditorDNDView _viewThatContainsDrag: null

    readonly property PlayerControlbarModel model: MainCtx.controlbarProfileModel.currentModel?.getModel(identifier) ?? null

    readonly property bool changed: (MainCtx.controlbarProfileModel.currentModel?.dirty ?? false)
                                    || (MainCtx.controlbarProfileModel.selectedProfile !== openedProfile)

    property int _revision: 0

    Connections {
        target: root.model

        function onControlListChanged() {
            ++root._revision
        }
    }

    signal dragStarted(int controlId)
    signal dragStopped(int controlId)

    signal accepted()
    signal rejected()

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    readonly property real _rowHeight: VLCStyle.dp(54, VLCStyle.scale)
    readonly property real _barPadding: VLCStyle.dp(20, VLCStyle.scale)

    function _markDirty(text) {
        return (text += " *")
    }

    function newProfile(profileCreatorFunction) {
        console.assert(typeof profileCreatorFunction === 'function')

        const count = MainCtx.controlbarProfileModel.rowCount()
        const npDialog = DialogsProvider.getTextDialog(null,
                                                       qsTr("Profile Name"),
                                                       qsTr("Please enter the new profile name:"),
                                                       qsTr("Profile %1").arg(count + 1))
        if (!npDialog.ok)
            return

        profileCreatorFunction(npDialog.text)
        MainCtx.controlbarProfileModel.selectedProfile = count
    }

    Keys.onEscapePressed: (event) => {
        if (!buttonDragItem.Drag.active)
            root.rejected()
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent

            acceptedButtons: Qt.AllButtons

            cursorShape: root.dragActive ? Qt.ForbiddenCursor : Qt.ArrowCursor
        }
    }

    Rectangle {
        id: card

        readonly property real availableTop: VLCStyle.margin_normal
        readonly property real availableBottom: root.height - VLCStyle.dp(62, VLCStyle.scale)

        anchors.horizontalCenter: parent.horizontalCenter
        y: availableTop + Math.max(0, (availableBottom - availableTop - height) / 2)

        width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), root.width - 2 * VLCStyle.margin_normal)
        height: Math.min(cardLayout.implicitHeight, availableBottom - availableTop)

        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: theme.palette.bgB1

        Accessible.role: Accessible.Dialog
        Accessible.name: title.text

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
            radius: card.radius

            opacity: theme.palette.isDark ? 0.46 : 0.18

            color: "black"
        }

        // Dropping a control of the bar on the dialog removes it.
        DropArea {
            id: removeArea

            anchors.fill: parent

            onEntered: (drag) => {
                if (!drag.source || drag.source.objectName === "buttonsList" || !drag.source.dndView)
                    drag.accepted = false
            }

            onDropped: (drop) => {
                drop.source.dndView.model.remove(drop.source.DelegateModel.itemsIndex)
                drop.accept(Qt.MoveAction)
            }
        }

        ColumnLayout {
            id: cardLayout

            anchors.fill: parent

            spacing: 0

            Rectangle {
                Layout.fillWidth: true

                implicitHeight: headerLayout.implicitHeight + 2 * VLCStyle.dp(9, VLCStyle.scale)

                radius: card.radius
                color: theme.palette.bgB2

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    height: parent.radius

                    color: parent.color
                }

                ColumnLayout {
                    id: headerLayout

                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(9, VLCStyle.scale)
                    anchors.leftMargin: VLCStyle.dp(19, VLCStyle.scale)

                    spacing: VLCStyle.margin_small

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                        spacing: VLCStyle.margin_xsmall

                        T.Label {
                            id: title

                            Layout.fillWidth: true

                            text: qsTr("Customize Player")
                            color: theme.palette.fgA2
                            font.pixelSize: VLCStyle.fontSize_large
                            elide: Text.ElideRight

                            Accessible.role: Accessible.Heading
                        }

                        Rectangle {
                            implicitWidth: tabs.implicitWidth + 2 * VLCStyle.margin_xxxsmall
                            implicitHeight: tabs.implicitHeight + 2 * VLCStyle.margin_xxxsmall

                            radius: VLCStyle.dp(6, VLCStyle.scale)
                            color: tabTheme.bg.primary

                            readonly property ColorContext colorContext: ColorContext {
                                id: tabTheme
                                colorSet: ColorContext.Switch
                            }

                            Row {
                                id: tabs

                                anchors.centerIn: parent

                                spacing: VLCStyle.margin_xxxsmall

                                Accessible.role: Accessible.PageTabList
                                Accessible.name: qsTr("Player")

                                Repeater {
                                    // The mini player of the design has no control bar.
                                    model: PlayerListModel.model.filter(
                                               (entry) => entry.identifier !== PlayerControlbarModel.Miniplayer)

                                    delegate: EditorTabButton {
                                        readonly property int identifier: modelData.identifier

                                        checked: identifier === root.identifier

                                        text: {
                                            const text = modelData.name

                                            if (MainCtx.controlbarProfileModel.currentModel?.getModel(identifier).dirty)
                                                return root._markDirty(text)
                                            else
                                                return text
                                        }

                                        onClicked: root.identifier = identifier
                                        onDropEnterred: root.identifier = identifier
                                    }
                                }
                            }
                        }

                        Item {
                            implicitWidth: VLCStyle.margin_xsmall
                        }

                        Widgets.ComboBoxExt {
                            id: comboBox

                            Layout.preferredWidth: VLCStyle.dp(180, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                            textRole: "name"

                            displayText: {
                                const profile = MainCtx.controlbarProfileModel.currentModel
                                if (!profile)
                                    return "N/A"

                                return profile.dirty ? root._markDirty(profile.name) : profile.name
                            }

                            model: MainCtx.controlbarProfileModel

                            currentIndex: MainCtx.controlbarProfileModel.selectedProfile

                            onCurrentIndexChanged: {
                                MainCtx.controlbarProfileModel.selectedProfile = currentIndex
                            }

                            Accessible.name: qsTr("Profiles")
                        }

                        Widgets.IconToolButton {
                            description: qsTr("Clone the selected profile")
                            text: VLCIcons.ic_fluent_document_copy_24_regular

                            onClicked: root.newProfile(MainCtx.controlbarProfileModel.cloneSelectedProfile)
                        }

                        Widgets.IconToolButton {
                            description: qsTr("New profile")
                            text: VLCIcons.ic_fluent_document_add_24_regular

                            onClicked: root.newProfile(MainCtx.controlbarProfileModel.newProfile)
                        }

                        Widgets.IconToolButton {
                            description: qsTr("Delete the current profile.\nDeleting all profiles brings back the default styles.")
                            text: VLCIcons.del

                            onClicked: MainCtx.controlbarProfileModel.deleteSelectedProfile()
                        }

                        Widgets.IconToolButton {
                            description: qsTr("Close")
                            text: VLCIcons.close

                            onClicked: root.rejected()
                        }
                    }

                    T.Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                        text: qsTr("Drag items around and out of the box below to re-order them. Drag items into the box to remove them from the player.")
                        color: theme.palette.fgA3
                        font.pixelSize: VLCStyle.fontSize_large
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                id: body

                readonly property real padding: VLCStyle.dp(34, VLCStyle.scale)

                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitHeight: buttonList.implicitHeight + 2 * padding

                color: removeArea.containsDrag ? theme.palette.bgAccentDark : "transparent"

                ToolbarEditorButtonList {
                    id: buttonList

                    readonly property int columns: Math.max(1, Math.floor(width / cellWidth))
                    readonly property real tileHeight: VLCStyle.dp(82, VLCStyle.scale)

                    // The design shows four rows; the rest scrolls.
                    implicitHeight: Math.min(Math.ceil(count / columns), 4) * cellHeight - (cellHeight - tileHeight)

                    anchors.fill: parent
                    anchors.margins: body.padding
                    anchors.rightMargin: body.padding - VLCStyle.dp(24, VLCStyle.scale)

                    barModel: root.model
                    dragItem: buttonDragItem

                    onControlDragStarted: (id) => root.dragStarted(id)
                    onControlDragStopped: (id) => root.dragStopped(id)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: VLCStyle.dp(20, VLCStyle.scale)

                Widgets.DialogButton {
                    text: qsTr("Cancel")

                    onClicked: root.rejected()
                }

                Item {
                    Layout.fillWidth: true
                }

                Widgets.DialogButton {
                    text: qsTr("Save")
                    primary: true

                    enabled: root.changed
                    opacity: enabled ? 1.0 : 0.5

                    onClicked: root.accepted()
                }
            }
        }

        EditorDashedFrame {
            anchors.fill: parent

            visible: removeArea.containsDrag
            color: theme.palette.accent
        }
    }

    Rectangle {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: 2 * root._rowHeight

        color: theme.palette.bgA3

        Accessible.role: Accessible.Grouping
        Accessible.name: qsTr("Control bar layout")

        // Row above the controls: holds the seek bar when the layout does not
        // place it, and takes it back when it is dropped here.
        Item {
            id: topRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: root._rowHeight

            readonly property bool seekPlaced: {
                // Evaluated again whenever the edited layout changes.
                root._revision

                const model = root.model
                return !!model && [model.left, model.center, model.right].some(
                           (list) => list.contains(ControlListModel.POSITION_WIDGET))
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: VLCStyle.border
                color: theme.palette.dividerDim
            }

            DropArea {
                id: topDropArea

                anchors.fill: parent

                onEntered: (drag) => {
                    if (!drag.source || drag.source.controlId !== ControlListModel.POSITION_WIDGET || !drag.source.dndView)
                        drag.accepted = false
                }

                onDropped: (drop) => {
                    drop.source.dndView.model.remove(drop.source.DelegateModel.itemsIndex)
                    drop.accept(Qt.MoveAction)
                }
            }

            EditorDashedFrame {
                anchors.fill: parent
                anchors.margins: VLCStyle.margin_xxsmall

                visible: topDropArea.containsDrag
                color: theme.palette.accent
            }

            MouseArea {
                id: seekSource

                anchors.fill: parent
                anchors.leftMargin: root._barPadding
                anchors.rightMargin: root._barPadding
                anchors.topMargin: VLCStyle.dp(9, VLCStyle.scale)
                anchors.bottomMargin: VLCStyle.dp(9, VLCStyle.scale)

                visible: !topRow.seekPlaced

                objectName: "buttonsList"
                readonly property int mIndex: ControlListModel.POSITION_WIDGET

                hoverEnabled: true
                cursorShape: Qt.OpenHandCursor

                drag.target: buttonDragItem
                drag.smoothed: false

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Seek Bar")

                drag.onActiveChanged: {
                    if (drag.active) {
                        root.dragStarted(mIndex)

                        buttonDragItem.text = PlayerControlbarControls.control(mIndex).label ?? ""
                        buttonDragItem.Drag.source = this
                        buttonDragItem.Drag.start()
                    } else {
                        buttonDragItem.Drag.drop()

                        root.dragStopped(mIndex)
                    }
                }

                onPressed: (mouse) => {
                    const pos = mapToItem(buttonDragItem.parent, mouseX, mouseY)
                    buttonDragItem.y = pos.y - buttonDragItem.height / 2
                    buttonDragItem.x = pos.x - buttonDragItem.width / 2
                }

                EditorDashedFrame {
                    anchors.fill: parent

                    color: seekSource.containsMouse ? theme.palette.fgA2 : theme.palette.fgA3
                }
            }

            EditorPositionPreview {
                anchors.fill: seekSource
                anchors.margins: VLCStyle.margin_xxxsmall

                z: -1

                visible: seekSource.visible
            }
        }

        Item {
            id: controlsRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: root._rowHeight

            readonly property real zoneGap: VLCStyle.dp(20, VLCStyle.scale)
            readonly property real emptyZoneWidth: VLCStyle.dp(40, VLCStyle.scale)

            readonly property bool centerStretches: {
                const center = root.model?.center
                if (!center || center.count === 0)
                    return false
                return center.contains(ControlListModel.POSITION_WIDGET)
                        || center.contains(ControlListModel.WIDGET_SPACER_EXTEND)
            }

            function zoneWidth(view) {
                if (view.count > 0)
                    return view.contentWidth
                return root.dragActive ? emptyZoneWidth : 0
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: VLCStyle.border
                color: theme.palette.dividerDim
            }

            EditorZone {
                id: leftZone

                x: root._barPadding
                width: controlsRow.zoneWidth(view)

                view.model: root.model?.left ?? null
                view.spacing: VLCStyle.margin_xsmall

                // Like the control bar, a stretching control here takes the
                // room up to the next group.
                view.availableWidth: {
                    if (controlsRow.centerStretches)
                        return -1
                    if (centerZone.view.count === 0)
                        return rightZone.x - controlsRow.zoneGap - x
                    return centerZone.x - controlsRow.zoneGap - x
                }

                regionStart: 0
                regionEnd: x + width + controlsRow.zoneGap
            }

            EditorZone {
                id: centerZone

                readonly property real stretchStart: leftZone.x + leftZone.width + controlsRow.zoneGap

                x: controlsRow.centerStretches ? stretchStart : (controlsRow.width - width) / 2
                width: controlsRow.centerStretches
                       ? Math.max(controlsRow.emptyZoneWidth, rightZone.x - controlsRow.zoneGap - stretchStart)
                       : controlsRow.zoneWidth(view)

                view.model: root.model?.center ?? null
                view.spacing: VLCStyle.margin_xsmall
                view.availableWidth: controlsRow.centerStretches ? width : -1

                regionStart: leftZone.regionEnd
                regionEnd: rightZone.regionStart
            }

            EditorZone {
                id: rightZone

                x: controlsRow.width - root._barPadding - width
                width: controlsRow.zoneWidth(view)

                view.model: root.model?.right ?? null
                view.spacing: VLCStyle.margin_small

                view.availableWidth: (controlsRow.centerStretches || centerZone.view.count === 0)
                                     ? -1
                                     : controlsRow.width - root._barPadding - (centerZone.x + centerZone.width + controlsRow.zoneGap)

                regionStart: x - controlsRow.zoneGap
                regionEnd: controlsRow.width
            }
        }
    }

    EditorDummyButton {
        id: buttonDragItem

        visible: Drag.active

        color: theme.palette.fgA2
        frameColor: theme.palette.accent
        backgroundColor: theme.palette.bgA3

        x: -1
        y: -1

        Drag.onActiveChanged: {
            dragAutoScrollHandler.dragItem = Drag.active ? this : null
        }
    }

    ViewDragAutoScrollHandler {
        id: dragAutoScrollHandler

        view: _viewThatContainsDrag ?? null
    }
}
