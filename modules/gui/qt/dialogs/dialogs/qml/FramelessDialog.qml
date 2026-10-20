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

    // the size the dialog takes when the screen has room for it
    property real baseWidth: VLCStyle.dp(1048, VLCStyle.scale)
    property real baseHeight: VLCStyle.dp(800, VLCStyle.scale)

    // the text of the title bar
    property string heading: title
    // items placed in the title bar before the heading
    property alias leadingData: leadingItem.data
    property alias toolbarData: toolbarItem.data
    default property alias contentData: content.data

    property string acceptText: qsTr("Save")
    property bool acceptEnabled: true
    property bool cancelVisible: true
    property bool footerVisible: true
    property alias footerData: footerExtra.data

    // a separate window cannot show the dimmed interface through it, so it is
    // drawn a shade darker than bgA3 to keep bgA3 buttons visible
    property color backgroundColor: Qt.tint(theme.palette.bgA3, Qt.rgba(0, 0, 0, 0.08))
    property color headerColor: theme.palette.isDark ? theme.palette.bgB2 : theme.palette.bgA3

    readonly property ColorContext colorContext: frame.colorContext

    signal accepted()
    signal rejected()

    transientParent: MainCtx.intfMainWindow

    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal

    width: Math.min(baseWidth, Screen.desktopAvailableWidth - VLCStyle.margin_xlarge)
    height: Math.min(baseHeight, Screen.desktopAvailableHeight - VLCStyle.margin_xlarge)

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
                    color: root.headerColor

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

                            Item {
                                id: leadingItem

                                Layout.fillHeight: true
                                Layout.preferredWidth: childrenRect.width

                                visible: children.length > 0
                            }

                            Widgets.LabelExt {
                                Layout.fillWidth: true
                                Layout.leftMargin: leadingItem.visible ? VLCStyle.dp(32, VLCStyle.scale)
                                                                       : VLCStyle.dp(10, VLCStyle.scale)

                                text: root.heading
                                elide: Text.ElideRight
                                color: theme.palette.fgA2
                                font.pixelSize: VLCStyle.fontSize_normal
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
                    visible: root.footerVisible

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
