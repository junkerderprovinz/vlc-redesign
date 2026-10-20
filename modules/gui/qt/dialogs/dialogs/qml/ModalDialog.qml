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
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Dialog {
    id: control

    property Item rootWindow: null

    property bool closeButtonVisible: true

    readonly property real radius: VLCStyle.dp(14, VLCStyle.scale)

    focus: true
    modal: true


    anchors.centerIn: T.Overlay.overlay

    topPadding: VLCStyle.dp(22, VLCStyle.scale)
    bottomPadding: VLCStyle.dp(22, VLCStyle.scale)
    leftPadding: VLCStyle.dp(20, VLCStyle.scale)
    rightPadding: VLCStyle.dp(20, VLCStyle.scale)
    margins: VLCStyle.margin_large
    spacing: 0

    implicitWidth: Math.max(contentWidth > 0 ? contentWidth + leftPadding + rightPadding : 0,
                            (header && header.visible) ? header.implicitWidth : 0,
                            (footer && footer.visible) ? footer.implicitWidth : 0)
    implicitHeight: (header && header.visible ? header.implicitHeight + spacing : 0)
                    + (footer && footer.visible ? footer.implicitHeight + spacing : 0)
                    + (contentHeight > 0 ? contentHeight + topPadding + bottomPadding : 0)

    font.pixelSize: VLCStyle.fontSize_large

    closePolicy: Popup.CloseOnEscape

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.ComboBox
    }

    T.Overlay.modal: Item {
        Rectangle {
            anchors.fill: blur

            visible: !blur.visible

            color: "black"

            opacity: theme.palette.isDark ? 0.45 : 0.2
        }

        Widgets.DualKawaseBlur {
            id: blur

            anchors.fill: parent
            anchors.margins: MainCtx.windowExtendedMargin

            visible: MainCtx.backdropBlurRequested() && blur.available

            mode: Widgets.DualKawaseBlur.Mode.SixPass

            source: ShaderEffectSource {
                sourceItem: blur.visible ? control.rootWindow : null
                live: true
                hideSource: true
            }

            radius: 2
        }
    }

    background: Rectangle {
        color: theme.bg.neutral
        radius: control.radius

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.margin_xsmall
            blurRadius: VLCStyle.dp(8, VLCStyle.scale)

            visible: (parent.color.a > 0.0)

            color: theme.shadow
        }
    }

    header: Rectangle {
        implicitWidth: titleRow.implicitWidth + titleRow.anchors.leftMargin + titleRow.anchors.rightMargin
        implicitHeight: VLCStyle.dp(50, VLCStyle.scale)

        visible: control.title || control.closeButtonVisible

        radius: control.radius
        color: theme.bg.primary

        readonly property ColorContext colorContext: ColorContext {
            palette: theme.palette
        }

        // square off the bottom corners
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: parent.radius

            color: parent.color
        }

        RowLayout {
            id: titleRow

            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dp(19, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(9, VLCStyle.scale)

            spacing: VLCStyle.margin_xsmall

            T.Label {
                text: control.title
                elide: Label.ElideRight
                color: theme.fg.primary
                font.pixelSize: VLCStyle.fontSize_large
                textFormat: Text.PlainText

                Layout.fillWidth: true
            }

            Widgets.IconToolButton {
                visible: control.closeButtonVisible

                implicitWidth: VLCStyle.margin_xlarge
                implicitHeight: VLCStyle.margin_xlarge

                text: VLCIcons.close
                description: qsTr("Close")

                font.pixelSize: VLCStyle.icon_normal

                focusPolicy: Qt.NoFocus

                onClicked: control.reject()
            }
        }
    }

    exit: Transition {
        OpacityAnimator { from: 1.0; to: 0.0 }
    }
    enter: Transition {
        OpacityAnimator { from: 0.0; to: 1.0 }
    }
}
