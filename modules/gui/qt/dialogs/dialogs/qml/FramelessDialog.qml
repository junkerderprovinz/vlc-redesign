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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style

// A dialog window that draws its own title bar, an optional toolbar row
// below the title and a Cancel / accept footer.
Window {
    id: root

    property real designWidth: VLCStyle.dp(1048, VLCStyle.scale)
    property real designHeight: VLCStyle.dp(800, VLCStyle.scale)

    property alias toolbarData: toolbarItem.data
    default property alias contentData: content.data

    property string acceptText: qsTr("Save")
    property bool acceptEnabled: true
    property bool cancelVisible: true
    property alias footerData: footerExtra.data

    property color backgroundColor: theme.palette.bgA3

    readonly property ColorContext colorContext: frame.colorContext

    signal accepted()
    signal rejected()

    transientParent: MainCtx.intfMainWindow

    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal

    width: Math.min(designWidth, Screen.desktopAvailableWidth - VLCStyle.margin_xlarge)
    height: Math.min(designHeight, Screen.desktopAvailableHeight - VLCStyle.margin_xlarge)

    color: "transparent"

    function open() {
        const parentWindow = MainCtx.intfMainWindow
        if (parentWindow) {
            x = parentWindow.x + (parentWindow.width - width) / 2
            y = parentWindow.y + (parentWindow.height - height) / 2
        }
        show()
        requestActivate()
    }

    function accept() {
        if (!acceptEnabled)
            return
        accepted()
        hide()
    }

    function reject() {
        rejected()
        hide()
    }

    onClosing: rejected()

    // assigned to a property, not to the default property that holds the content
    readonly property Item _frame: Rectangle {
        id: frame

        parent: root.contentItem
        width: root.width
        height: root.height

        readonly property ColorContext colorContext: ColorContext {
            id: theme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: root.backgroundColor

        FocusScope {
            anchors.fill: parent

            focus: true

            Keys.onEscapePressed: root.reject()

            ColumnLayout {
                anchors.fill: parent

                spacing: 0

                Rectangle {
                    id: header

                    Layout.fillWidth: true
                    Layout.preferredHeight: headerLayout.implicitHeight + 2 * headerLayout.anchors.margins

                    radius: frame.radius
                    color: theme.palette.isDark ? theme.palette.bgB2 : theme.palette.bgA3

                    // square off the lower corners
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.radius
                        color: parent.color
                    }

                    DragHandler {
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything
                        onActiveChanged: {
                            if (active)
                                root.startSystemMove()
                        }
                    }

                    ColumnLayout {
                        id: headerLayout

                        anchors.fill: parent
                        anchors.margins: VLCStyle.dp(9, VLCStyle.scale)

                        spacing: VLCStyle.margin_small

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                            spacing: 0

                            Widgets.LabelExt {
                                Layout.fillWidth: true
                                Layout.leftMargin: VLCStyle.dp(10, VLCStyle.scale)

                                text: root.title
                                elide: Text.ElideRight
                                color: theme.palette.fgA2
                                font.pixelSize: VLCStyle.fontSize_large
                                textFormat: Text.PlainText
                            }

                            Widgets.IconToolButton {
                                Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                                Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                font.pixelSize: VLCStyle.icon_normal

                                text: VLCIcons.close
                                description: qsTr("Close")

                                onClicked: root.reject()
                            }
                        }

                        FocusScope {
                            id: toolbarItem

                            Layout.fillWidth: true
                            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)

                            visible: children.length > 0
                            focus: true
                        }
                    }
                }

                Item {
                    id: content

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: VLCStyle.dp(20, VLCStyle.scale)

                    spacing: VLCStyle.dp(20, VLCStyle.scale)

                    Widgets.DialogButton {
                        visible: root.cancelVisible

                        text: qsTr("Cancel")

                        onClicked: root.reject()
                    }

                    Item {
                        id: footerExtra

                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
                    }

                    Widgets.DialogButton {
                        primary: true
                        text: root.acceptText
                        enabled: root.acceptEnabled

                        onClicked: root.accept()
                    }
                }
            }
        }
    }
}
