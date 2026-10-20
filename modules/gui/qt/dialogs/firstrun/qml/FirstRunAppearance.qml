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
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

FocusScope {
    id: root

    required property FirstRunController controller

    readonly property bool hasAside: true

    readonly property var accentNames: [
        qsTr("Orange"), qsTr("Red"), qsTr("Yellow"), qsTr("Green"), qsTr("Cyan"),
        qsTr("Blue"), qsTr("Purple"), qsTr("Pink"), qsTr("Grey")
    ]

    readonly property int accentIndex: {
        const current = MainCtx.accentColor.toString().toLowerCase()
        return VLCStyle.accentColors.findIndex((color) => color.toLowerCase() === current)
    }

    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    FirstRunPreview {
        x: VLCStyle.dp(17, VLCStyle.scale)
        y: VLCStyle.dp(19, VLCStyle.scale)
        width: VLCStyle.dp(1056, VLCStyle.scale)
        height: VLCStyle.dp(594, VLCStyle.scale)
    }

    T.Label {
        anchors.left: parent.left
        anchors.right: parent.right
        y: VLCStyle.dp(173, VLCStyle.scale)

        text: qsTr("Select your preferred theme and color.")
        color: VLCStyle.palette.fgA1
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
        font.weight: Font.Light
        lineHeight: VLCStyle.dp(42, VLCStyle.scale)
        lineHeightMode: Text.FixedHeight
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: VLCStyle.dp(286, VLCStyle.scale)

        spacing: VLCStyle.dp(40, VLCStyle.scale)

        Accessible.role: Accessible.Grouping
        Accessible.name: qsTr("Theme")

        ThemeCard {
            id: lightCard

            scheme: ColorSchemeModel.Day
            text: qsTr("Light")

            Navigation.rightItem: darkCard
        }

        ThemeCard {
            id: darkCard

            scheme: ColorSchemeModel.Night
            text: qsTr("Dark")

            Navigation.leftItem: lightCard
            Navigation.rightItem: systemCard
        }

        ThemeCard {
            id: systemCard

            scheme: ColorSchemeModel.System
            text: qsTr("System")

            Navigation.leftItem: darkCard
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: VLCStyle.dp(470, VLCStyle.scale)

        spacing: VLCStyle.dp(10, VLCStyle.scale)

        Widgets.SegmentedControl {
            id: layoutChoice

            anchors.horizontalCenter: parent.horizontalCenter
            width: VLCStyle.dp(240, VLCStyle.scale)
            segmentHeight: VLCStyle.dp(32, VLCStyle.scale)
            font.pixelSize: VLCStyle.fontSize_normal

            model: [qsTr("Modern"), qsTr("Classic")]
            currentIndex: root.controller.classicLayout ? 1 : 0

            Accessible.name: qsTr("Layout")

            Navigation.parentItem: root
            Navigation.upItem: lightCard.checked ? lightCard : (darkCard.checked ? darkCard : systemCard)
            Navigation.downItem: accentRepeater.itemAt(0)

            onActivated: (index) => root.controller.classicLayout = (index === 1)
        }

        T.Label {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.controller.classicLayout
                  ? qsTr("<i>VLC will use a classic layout with a menubar and pinned controls but with no client-side decoration</i>")
                  : qsTr("<i>VLC will use a modern layout with no menubar or pinned controls but with client-side decoration</i>")
            textFormat: Text.StyledText
            color: VLCStyle.palette.fgA3
            font.pixelSize: VLCStyle.fontSize_normal
        }
    }

    Row {
        x: VLCStyle.dp(41, VLCStyle.scale)
        y: VLCStyle.dp(655, VLCStyle.scale)
        height: VLCStyle.dp(64, VLCStyle.scale)

        // ten swatches have to fit beside the footer buttons
        spacing: VLCStyle.dp(12, VLCStyle.scale)

        Accessible.role: Accessible.Grouping
        Accessible.name: qsTr("Accent color")

        Repeater {
            id: accentRepeater

            model: VLCStyle.accentColors

            delegate: AccentSwatch {
                required property string modelData
                required property int index

                swatch: modelData
                text: root.accentNames[index] ?? modelData
                checked: index === root.accentIndex

                Navigation.leftItem: index > 0 ? accentRepeater.itemAt(index - 1) : null
                Navigation.rightItem: index < accentRepeater.count - 1 ? accentRepeater.itemAt(index + 1)
                                                                       : customSwatch

                onClicked: {
                    if (index === 0)
                        MainCtx.accentColor = undefined
                    else
                        MainCtx.accentColor = modelData
                }
            }
        }

        AccentSwatch {
            id: customSwatch

            swatch: checked ? MainCtx.accentColor : "transparent"
            text: qsTr("Custom color")
            checked: root.accentIndex < 0

            Navigation.leftItem: accentRepeater.itemAt(accentRepeater.count - 1)

            onClicked: {
                picker.setColor(MainCtx.accentColor)
                picker.open()
            }

            SettingsColorPicker {
                id: picker

                x: customSwatch.width - width
                y: -height - VLCStyle.dp(6, VLCStyle.scale)

                onPicked: (c) => MainCtx.accentColor = c
            }

            Rectangle {
                anchors.centerIn: parent
                width: VLCStyle.dp(40, VLCStyle.scale)
                height: width
                radius: width / 2

                visible: !customSwatch.checked
                color: "transparent"
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: VLCStyle.palette.fgA3

                Widgets.IconLabel {
                    anchors.centerIn: parent

                    text: VLCIcons.add
                    color: VLCStyle.palette.fgA2
                    font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                }
            }
        }
    }

    component ThemeCard: T.AbstractButton {
        id: card

        required property int scheme

        width: VLCStyle.dp(116, VLCStyle.scale)
        height: VLCStyle.dp(157, VLCStyle.scale)

        checked: MainCtx.colorScheme.scheme === scheme
        focus: checked
        hoverEnabled: true

        Navigation.parentItem: root
        Navigation.downItem: layoutChoice
        Keys.priority: Keys.AfterItem
        Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

        Accessible.role: Accessible.RadioButton

        onClicked: root.controller.setColorScheme(scheme)

        Rectangle {
            width: parent.width
            height: width
            radius: VLCStyle.dp(19, VLCStyle.scale)

            color: "transparent"
            border.width: card.checked ? VLCStyle.dp(4, VLCStyle.scale)
                                       : (card.hovered || card.visualFocus) ? VLCStyle.dp(2, VLCStyle.scale) : 0
            border.color: (card.checked || card.visualFocus) ? VLCStyle.palette.accent
                                                             : VLCStyle.palette.dividerBright

            // the swatches picture each theme, so they keep their colors in any theme
            Rectangle {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(8, VLCStyle.scale)

                visible: card.scheme !== ColorSchemeModel.System
                radius: VLCStyle.dp(12, VLCStyle.scale)
                color: card.scheme === ColorSchemeModel.Night ? "#222222" : "#afafaf"
            }

            Image {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(8, VLCStyle.scale)

                visible: card.scheme === ColorSchemeModel.System
                sourceSize: Qt.size(width, height)
                source: visible ? "qrc:///icons/ui/theme-system.svg" : ""
            }
        }

        T.Label {
            anchors.bottom: parent.bottom
            width: parent.width

            text: card.text
            color: VLCStyle.palette.fgA2
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Light
        }
    }

    component AccentSwatch: T.AbstractButton {
        id: accent

        property color swatch

        width: VLCStyle.dp(64, VLCStyle.scale)
        height: width

        hoverEnabled: true

        opacity: (checked || visualFocus) ? 1 : (hovered ? 0.8 : 0.5)

        Behavior on opacity {
            NumberAnimation { duration: VLCStyle.duration_short }
        }

        Navigation.parentItem: root
        Navigation.upItem: layoutChoice
        Keys.priority: Keys.AfterItem
        Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

        Accessible.role: Accessible.RadioButton

        T.ToolTip.visible: hovered
        T.ToolTip.delay: VLCStyle.delayToolTipAppear
        T.ToolTip.text: text

        background: Rectangle {
            radius: width / 2

            color: "transparent"
            border.width: (accent.checked || accent.visualFocus) ? VLCStyle.dp(4, VLCStyle.scale) : 0
            border.color: accent.visualFocus ? VLCStyle.palette.accent
                                             : Qt.rgba(accent.swatch.r, accent.swatch.g, accent.swatch.b, 0.3)

            Rectangle {
                anchors.centerIn: parent
                width: VLCStyle.dp(40, VLCStyle.scale)
                height: width
                radius: width / 2

                color: accent.swatch
            }
        }
    }
}
