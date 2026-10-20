/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
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
import QtQml.Models
import QtQuick.Window
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Playlist
import VLC.Player
import VLC.PlayerControls
import VLC.Dialogs
import VLC.Util

FocusScope {
    id: rootPlayer

    // Properties

    //behave like a Page
    property var pagePrefix: []

    readonly property int positionSliderY: controlBar.y + controlBar.sliderY

    readonly property string coverSource: {
        if (Player.artwork &&
            Player.artwork.toString())
            return Player.artwork
        else if (Player.hasVideoOutput)
            return VLCStyle.noArtVideoCover
        else
            return VLCStyle.noArtAlbumCover
    }

    // Private

    property bool _controlsUnderVideo: (MainCtx.pinVideoControls
                                        &&
                                        (MainCtx.intfMainWindow.visibility !== Window.FullScreen))

    property bool _keyPressed: false

    // Settings

    Accessible.role: Accessible.Client
    Accessible.name: qsTr("Player")
    AccessibleCompat.id: "playerView"

    // Events

    Component.onCompleted: MainCtx.preferHotkeys = true
    Component.onDestruction: MainCtx.preferHotkeys = false

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => {
        if (event.accepted)
            return

        _keyPressed = true

        rootPlayer.Navigation.defaultKeyAction(event)

        //unhandled keys are forwarded as hotkeys
        if (!event.accepted || controlBar.state !== "visible")
            MainCtx.sendHotkey(event.key, event.modifiers);
    }

    Keys.onReleased: (event) => {
        if (event.accepted || _keyPressed === false)
            return

        _keyPressed = false

        rootPlayer.Navigation.defaultKeyReleaseAction(event)
    }

    on_ControlsUnderVideoChanged: {
        lockUnlockAutoHide(_controlsUnderVideo)
    }

    // Functions

    function lockUnlockAutoHide(lock) {
        if (lock) {
            playerToolbarVisibilityFSM.lock()
        } else {
            playerToolbarVisibilityFSM.unlock()
        }
    }

    // Private

    function _onNavigationCancel() {
        if (MainCtx.hasEmbededVideo && !MainCtx.canShowVideoPIP) {
            MainPlaylistController.stop()
        }

        History.previous()
    }

    //we draw both the view and the window here
    ColorContext {
        id: windowTheme

        // NOTE: We force the night theme when playing a video.
        palette: (MainCtx.hasEmbededVideo && MainCtx.pinVideoControls === false)
                 ? VLCStyle.darkPalette
                 : VLCStyle.palette

        colorSet: ColorContext.Window
    }

    PlayerToolbarVisibilityFSM {
        id: playerToolbarVisibilityFSM

        onForceUnlock:{
            controlBar.forceUnlock()

            topBar.forceUnlock()
        }
    }

    PlayerPlaylistVisibilityFSM {
        id: playlistVisibility

        onIsPlaylistVisibleChanged: lockUnlockAutoHide(isPlaylistVisible)
    }

    Connections {
        target: MainCtx

        //playlist
        function onHasEmbededVideoChanged() {
            playlistVisibility.updateVideoEmbed()
            playerToolbarVisibilityFSM.updateVideoEmbed()
        }
        function onAskShow() {
            playerToolbarVisibilityFSM.askShow()
        }
    }


    Connections {
        target: MainCtx.playqueuePanel

        //playlist
        function onDockedChanged() {
            playlistVisibility.updatePlaylistDocked()
        }
        function onVisibleChanged() {
            playlistVisibility.updatePlaylistVisible()
        }
    }


    Loader {
        id: playerSpecializationLoader

        objectName: "playerSpecializationLoader"

        anchors {
            left: parent.left
            right: parent.right
            top: (MainCtx.hasEmbededVideo && rootPlayer._controlsUnderVideo) ? topBar.bottom : parent.top
            bottom: (MainCtx.hasEmbededVideo && rootPlayer._controlsUnderVideo) ? controlBar.top : parent.bottom
        }

        sourceComponent: MainCtx.hasEmbededVideo ? videoComponent : audioComponent

        property int cursorShape

        // Have padding here, so that the content (unlike background) does not go behind the top bar or the control bar:
        property real topPadding: (anchors.top === parent.top) ? topBar.height : 0
        property real bottomPadding: (anchors.bottom === parent.bottom) ? controlBar.height : 0

        component TouchDragHandler : DragHandler {
            id: touchDragHandler

            acceptedDevices: PointerDevice.TouchScreen

            minimumPointCount: 1
            maximumPointCount: 1

            target: null

            dragThreshold: VLCStyle.margin_normal

            property vector2d lastActiveTranslation

            // TODO: Use `createComponent()` and load directly from module instead, since
            //       it is pointless to keep the `QQmlComponent` around for this object.
            readonly property Component wheelToVLCConverterComponent: Component { WheelToVLCConverter { } }

            property WheelToVLCConverter wheelToVLCConverter

            // We synthesize wheel event with pixel delta. It is a to-do to handle
            // touch properly with precision adjustment, like on Android:
            onActiveTranslationChanged: {
                if (active) {
                    console.assert(wheelToVLCConverter)

                    const delta = Qt.point(activeTranslation.x - lastActiveTranslation.x,
                                           activeTranslation.y - lastActiveTranslation.y)

                    // WheelToVLCConverter can not handle sole pixel delta now, so we also
                    // use angle delta. This is similar to wheel events on some platforms:
                    wheelToVLCConverter.customWheelEvent(delta,
                                                         delta,
                                                         Qt.NoButton,
                                                         Qt.NoModifier,
                                                         true)

                    lastActiveTranslation = activeTranslation
                }
            }

            onActiveChanged: {
                if (active) {
                    if (!wheelToVLCConverter) {
                        wheelToVLCConverter = wheelToVLCConverterComponent.createObject(touchDragHandler)
                        wheelToVLCConverter.vlcWheelKey.connect(MainCtx, MainCtx.sendVLCHotkey)
                    }
                } else {
                    lastActiveTranslation = Qt.vector2d(0, 0)
                }
            }
        }

        Component {
            id: videoComponent

            FocusScope {
                id: videoScope

                // Video

                focus: true

                // The video sits in a rounded frame of the window colour, except between
                // the bars of the light theme, where it fills the space.
                readonly property bool framed: !rootPlayer._controlsUnderVideo || windowTheme.tokens.isDark
                readonly property real frameWidth: framed ? VLCStyle.dp(10, VLCStyle.scale) : 0

                VideoSurface {
                    id: videoSurface

                    anchors.fill: parent
                    anchors.leftMargin: videoScope.frameWidth
                    anchors.rightMargin: videoScope.frameWidth
                    anchors.topMargin: rootPlayer._controlsUnderVideo ? (videoScope.framed ? VLCStyle.dp(1, VLCStyle.scale) : 0)
                                                                      : videoScope.frameWidth
                    anchors.bottomMargin: rootPlayer._controlsUnderVideo ? 0 : videoScope.frameWidth

                    // With regard to `ViewBlockingRectangle`, we
                    // do not need to prevent painting anything
                    // behind because there is already nothing
                    // behind (unlike pip player):
                    renderingEnabled: false

                    videoSurfaceProvider: MainCtx.videoSurfaceProvider

                    visible: MainCtx.hasEmbededVideo

                    focus: true

                    cursorShape: playerSpecializationLoader.cursorShape

                    function onMouseEvent() {
                        //short interval for mouse events
                        if (Player.isInteractive)
                            interactiveAutoHideTimer.restart()
                        else
                            playerToolbarVisibilityFSM.mouseMove();
                    }

                    Component.onCompleted: {
                        mouseMoved.connect(videoSurface.onMouseEvent)
                        mousePressed.connect(videoSurface.onMouseEvent)
                        mouseReleased.connect(videoSurface.onMouseEvent)
                        mouseDblClicked.connect(videoSurface.onMouseEvent)
                    }

                    Binding on cursorShape {
                        when: playerToolbarVisibilityFSM.started
                            && !playerToolbarVisibilityFSM.isVisible
                            && !interactiveAutoHideTimer.running
                        value: Qt.BlankCursor
                    }

                    TouchDragHandler {

                    }
                }

                VideoFrame {
                    anchors.fill: parent

                    target: videoSurface
                    frameWidth: videoScope.frameWidth
                    color: windowTheme.bg.primary
                }
            }
        }

        Component {
            id: audioComponent

            FocusScope {
                id: audioFocusScope
                // Audio

                focus: true

                property real topPadding: playerSpecializationLoader.topPadding
                property real bottomPadding: playerSpecializationLoader.bottomPadding

                HoverHandler {
                    id: audioHover
                }

                // Whether the full lyrics view is active
                readonly property bool lyricsMode: MainCtx.lyricsMode
                readonly property bool lyricsLayoutActive: lyricsMode
                                                        && Player.hasLyrics
                                                        && centerContent.width > VLCStyle.colWidth(6)

                // Reset sync when entering lyrics mode
                onLyricsModeChanged: {
                    if (lyricsMode && lyricsLoader.item)
                        lyricsLoader.item.lyricsSyncToPlayback = true
                }

                // background image
                Widgets.DualKawaseBlur {
                    id: blurredBackground

                    // Six pass is free here since we release the intermediate layers
                    // through unsetting `live` (see `liveTimer`):
                    mode: Widgets.DualKawaseBlur.Mode.SixPass
                    radius: 2

                    // We disable live when everything settles through `liveTimer`,
                    // which is important to release intermediate layers with static
                    // source:
                    live: true

                    //destination aspect ratio
                    readonly property real dar: parent.width / parent.height

                    anchors.centerIn: parent
                    width: (cover.sar < dar) ? parent.width :  parent.height * cover.sar
                    height: (cover.sar < dar) ? parent.width / cover.sar :  parent.height

                    source: textureProviderIndirection

                    postprocess: true
                    tint: bgtheme.tokens.isDark ? "black" : "white"
                    tintStrength: 0.5
                    backgroundColor: bgtheme.bg.primary

                    readonly property ColorContext colorContext: ColorContext {
                        id: bgtheme
                        colorSet: ColorContext.View
                    }

                    // The window naturally clips the content, but having this saves some
                    // video memory, depending on the excess content in the last layer:
                    viewportRect: Qt.rect((width - parent.width) / 2, (height - parent.height) / 2, parent.width, parent.height)

                    sourceTextureProviderObserver.onTextureChanged: {
                        liveTimer.transientTurnOnLive()
                    }

                    TextureProviderIndirection {
                        id: textureProviderIndirection

                        // This should not be necessary anymore since `DualKawaseBlur`
                        // does not create layer for the source implicitly as `MultiEffect`
                        // or `FastBlur` does as they deem necessary (in this case, it
                        // is not necessary). But due to a Qt bug when `mipmap: true` is
                        // used where texture sampling becomes broken, we need this as
                        // `QSGTextureView` has a workaround for that bug. This is totally
                        // acceptable as there is virtually no overhead.
                        source: cover
                    }

                    Component.onCompleted: {
                        // Blur layers are effect-size dependent, so once the user starts resizing the window (hence the effect),
                        // we should either momentarily turn on live, or repeatedly call `scheduleUpdate()`. Due to the optimization,
                        // calling `scheduleUpdate()` would continuously create and release intermediate layers, which would be a
                        // really bad idea. So instead, we turn on live and after some time passes turn it off again.
                        widthChanged.connect(liveTimer, liveTimer.transientTurnOnLive)
                        heightChanged.connect(liveTimer, liveTimer.transientTurnOnLive)

                        // In case texture provider observer never signals texture change:
                        liveTimer.transientTurnOnLive()
                    }

                    Timer {
                        id: liveTimer

                        repeat: false
                        interval: VLCStyle.duration_humanMoment

                        function transientTurnOnLive() {
                            if (!blurredBackground.sourceTextureIsValid)
                                return
                            blurredBackground.live = true
                            liveTimer.restart()
                        }

                        onTriggered: {
                            blurredBackground.live = false
                        }
                    }
                }

                MouseArea {
                    id: centerContent

                    readonly property ColorContext colorContext: ColorContext {
                        id: centerTheme
                        colorSet: ColorContext.View
                    }

                    anchors.fill: parent
                    anchors.topMargin: VLCStyle.margin_xsmall + audioFocusScope.topPadding
                    anchors.bottomMargin: VLCStyle.margin_xsmall + audioFocusScope.bottomPadding

                    onWheel: (wheel) => {
                        wheel.accepted = true
                        wheelToVlc.qmlWheelEvent(wheel)
                    }

                    TouchDragHandler {
                        wheelToVLCConverter: wheelToVlc
                    }

                    WheelToVLCConverter {
                        id: wheelToVlc

                        onVlcWheelKey: (key) => MainCtx.sendVLCHotkey(key)
                    }

                    // ── Two-panel lyrics layout ────────────────────────
                    Item {
                        id: leftSideParent

                        visible: (opacity > 0.0) || (width > 0.0)

                        opacity: (lyricsLoader.item ? 1.0 : 0.0)

                        Behavior on opacity {
                            id: opacityBehavior

                            enabled: false

                            NumberAnimation {
                                duration: VLCStyle.duration_long

                                easing.type: Easing.InOutSine
                            }

                            Component.onCompleted: {
                                // The animation should not be used at initialization:
                                Qt.callLater(() => { opacityBehavior.enabled = true })
                            }
                        }

                        anchors.top: parent.top
                        anchors.topMargin: VLCStyle.margin_large
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left

                        width: lyricsLoader.item ? (parent.width * 0.6) : 0.0

                        Behavior on width {
                            id: widthBehavior

                            enabled: false

                            NumberAnimation {
                                duration: VLCStyle.duration_long

                                easing.type: Easing.InOutSine
                            }

                            Component.onCompleted: {
                                // The animation should not be used at initialization:
                                Qt.callLater(() => { widthBehavior.enabled = true })
                            }
                        }

                        Loader {
                            id: lyricsLoader

                            active: audioFocusScope.lyricsLayoutActive
                            sourceComponent: T.Pane {
                                // Swallow wheel events so scrolling the lyrics
                                // does not bubble up to the player and change
                                // the volume.
                                wheelEnabled: true

                                // Expose the inner Flickable's sync flag so the
                                // Loader's `item.lyricsSyncToPlayback` reaches
                                // through to LyricsFlickable in both directions.
                                property alias lyricsSyncToPlayback: lyricsFlickable.lyricsSyncToPlayback

                                implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                                        implicitContentWidth + leftPadding + rightPadding)
                                implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                                         implicitContentHeight + topPadding + bottomPadding)

                                contentItem: LyricsFlickable {
                                    id: lyricsFlickable

                                    onPlayerPositionChangeRequested: (time) => {
                                        Player.setTime(time)
                                        lyricsFlickable.lyricsSyncToPlayback = true
                                    }
                                }
                            }
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            height: Math.min(implicitHeight, parent.height)
                        }
                    }

                    Item {
                        id: rightSideParent

                        visible: leftSideParent.visible

                        anchors.top: parent.top
                        anchors.topMargin: VLCStyle.margin_large
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.left: leftSideParent.right
                    }

                    ColumnLayout {
                        parent: leftSideParent.visible ? rightSideParent : centerContent

                        anchors.centerIn: parent
                        spacing: 0

                        Item {
                            id: coverItem

                            readonly property real gap: Math.min(VLCStyle.dp(74, VLCStyle.scale), rootPlayer.height * 0.0685)

                            Layout.preferredHeight: Math.max(VLCStyle.icon_xlarge,
                                                             Math.min(VLCStyle.dp(738, VLCStyle.scale),
                                                                      centerContent.height - VLCStyle.dp(175, VLCStyle.scale) - gap))
                            Layout.preferredWidth: cover.paintedWidth
                            Layout.maximumHeight: centerContent.height
                            Layout.alignment: Qt.AlignHCenter

                            Image {
                                id: cover

                                //source aspect ratio
                                readonly property real sar: paintedWidth / paintedHeight
                                readonly property int maximumSize: Helpers.alignUp(VLCStyle.dp(738, VLCStyle.scale) * eDPR, 32)

                                readonly property real eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

                                readonly property url targetSource: VLCAccessImage.uri(rootPlayer.coverSource)

                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: targetSource
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                cache: false
                                asynchronous: true

                                // Drawn through `roundedCover`, which rounds its corners.
                                visible: false

                                onTargetSourceChanged: {
                                    cover.source = targetSource
                                }

                                onSourceChanged: {
                                    liveTimer.transientTurnOnLive()
                                }

                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        cover.source = VLCStyle.noArtAlbumCover
                                    }
                                }

                                sourceSize: Qt.size(maximumSize, maximumSize)

                                Component.onCompleted: {
                                    // After the update on source change, there can be another update when the mipmaps are generated.
                                    // We intentionally do not wait for this, initially using non-mipmapped source should be okay. As
                                    // the user should not be greeted with a black background until the mipmaps are ready, let alone
                                    // the possibility of knowing if the mipmaps are actually going to be ready as expected.
                                    // If the texture is not valid yet (which is signalled the latest), blur effect is going to queue
                                    // an update itself similar to the case when the source itself changes, so we do not check validity
                                    // of the texture here.
                                    blurredBackground.sourceTextureProviderObserver.hasMipmapsChanged.connect(blurredBackground,
                                                                                                              (hasMipmaps /*: bool */) => {
                                                                                                                  if (hasMipmaps) {
                                                                                                                      blurredBackground.scheduleUpdate()
                                                                                                                  }
                                                                                                              })
                                }
                            }

                            Widgets.ImageExt {
                                id: roundedCover

                                anchors.centerIn: cover

                                width: cover.paintedWidth
                                height: cover.paintedHeight

                                unboundTextureProviderItem: cover
                                fillMode: Image.Stretch
                                radius: VLCStyle.dp(20, VLCStyle.scale)

                                Accessible.role: Accessible.Graphic
                                Accessible.name: qsTr("Cover")

                                Widgets.RoundedRectangleShadow {
                                    color: Qt.rgba(1, 1, 1, .03)
                                    blurRadius: VLCStyle.dp(90, VLCStyle.scale)
                                }
                            }
                        }

                        Widgets.SubtitleLabel {
                            id: titleLabel

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: coverItem.gap
                            Layout.maximumWidth: centerContent.width - VLCStyle.margin_xlarge * 2

                            Binding on visible {
                                delayed: true
                                when: titleLabel.componentCompleted
                                value: centerContent.height > (titleLabel.y + titleLabel.height)
                            }

                            text: (Player.artist !== "") ? qsTr("%1 - %2").arg(Player.title).arg(Player.artist)
                                                          : Player.title
                            font.pixelSize: VLCStyle.fontSize_xxxlarge
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: windowTheme.tokens.fgA1
                            Accessible.description: qsTr("title")

                            property bool componentCompleted: false

                            Component.onCompleted: {
                                componentCompleted = true
                            }
                        }

                        Widgets.SubtitleLabel {
                            id: lyricsLabel

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: VLCStyle.margin_large
                            // Pin width and height so the surrounding centered
                            // column does not shift when the current lyric
                            // changes between empty / 1 line / 2 lines. Text
                            // exceeding two lines wraps then elides on line 2.
                            Layout.preferredWidth: parent.parent.width - VLCStyle.margin_xlarge * 2
                            Layout.preferredHeight: (lyricsLabelTextMetrics.height * 2) + VLCStyle.margin_xxxsmall

                            visible: false

                            Binding on visible {
                                delayed: true
                                when: lyricsLabel.componentCompleted

                                // Stay visible (reserving the 2-line slot) for the
                                // entire track when it has any lyrics, so the
                                // layout does not collapse between lyric lines.
                                value: Player.hasLyrics && !audioFocusScope.lyricsLayoutActive &&
                                       (centerContent.height > (lyricsLabel.y + lyricsLabel.height))
                            }

                            property bool componentCompleted: false

                            Component.onCompleted: {
                                componentCompleted = true
                            }

                            elide: Text.ElideRight

                            text: Player.currentLyric.text
                            font.pixelSize: VLCStyle.fontSize_xlarge
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                            color: centerTheme.fg.primary

                            // TODO: Do not use `Binding` when minimum Qt is 6.12:
                            Binding {
                                target: lyricsLabel
                                property: "mutabilityGroup"
                                when: (lyricsLabel.mutabilityGroup !== undefined)
                                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.ModerateMutabilityGroup
                                                                                              : Item.StaticMutabilityGroup
                            }

                            TextMetrics {
                                id: lyricsLabelTextMetrics
                                font: lyricsLabel.font
                                text: "TEXT"
                            }

                            Accessible.role: Accessible.StaticText
                            Accessible.name: qsTr("Lyrics")
                            Accessible.description: text
                        }

                        // These buttons take no room in the column, which keeps the cover centred,
                        // and only show up on hover or focus.
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: audioControls.implicitWidth
                            Layout.preferredHeight: 0

                            Widgets.NavigableRow {
                                id: audioControls

                                anchors.horizontalCenter: parent.horizontalCenter
                                y: VLCStyle.margin_normal

                                Binding on visible {
                                    delayed: true
                                    when: audioControls.componentCompleted
                                    value: Player.videoTracks.count === 0 && centerContent.height > (audioControls.parent.y + audioControls.y + audioControls.height)
                                }

                                opacity: (audioHover.hovered || audioControls.activeFocus) ? 1.0 : 0.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: VLCStyle.duration_short
                                    }
                                }

                                focus: true
                                spacing: VLCStyle.margin_xxsmall
                                Navigation.parentItem: rootPlayer
                                Navigation.upItem: topBar
                                Navigation.downItem: syncToPlaybackCheckBox

                                property bool componentCompleted: false

                                Component.onCompleted: {
                                    componentCompleted = true
                                }

                                Widgets.IconToolButton {
                                    text: VLCIcons.visualization
                                    font.pixelSize: VLCStyle.icon_normal
                                    onClicked: Player.toggleVisualization()
                                    description: qsTr("Visualization")

                                    AccessibleCompat.id: "audioVisualizationButton"
                                }

                                Widgets.IconToolButton {
                                    text: VLCIcons.topbar_music
                                    font.pixelSize: VLCStyle.icon_normal
                                    checked: MainCtx.lyricsMode
                                    onClicked: MainCtx.lyricsMode = !MainCtx.lyricsMode
                                    description: qsTr("Lyrics")

                                    Accessible.role: Accessible.Button
                                    Accessible.name: qsTr("Toggle lyrics view")
                                    AccessibleCompat.id: "audioLyricsButton"
                                }
                            }
                        }

                        // "Sync to Playback" checkbox pinned to bottom of right panel
                        Widgets.CheckBoxExt {
                            id: syncToPlaybackCheckBox

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: VLCStyle.margin_small

                            visible: false

                            Binding on visible {
                                delayed: true
                                when: syncToPlaybackCheckBox.componentCompleted
                                value: audioFocusScope.lyricsLayoutActive &&
                                       centerContent.height > (syncToPlaybackCheckBox.y + syncToPlaybackCheckBox.height)
                            }

                            property bool componentCompleted: false

                            Component.onCompleted: {
                                componentCompleted = true
                            }

                            text: qsTr("Sync lyrics to playback")
                            // Use a Binding element rather than an inline binding
                            // so manual clicks (which write `checked` directly)
                            // don't permanently break the source-of-truth link.
                            Binding on checked {
                                when: lyricsLoader.item
                                value: lyricsLoader.item ? lyricsLoader.item.lyricsSyncToPlayback : true
                                restoreMode: Binding.RestoreBindingOrValue
                            }
                            onClicked: {
                                if (lyricsLoader.item)
                                    lyricsLoader.item.lyricsSyncToPlayback = checked
                            }

                            Accessible.role: Accessible.CheckBox
                            Accessible.name: qsTr("Sync lyrics to playback position")
                            AccessibleCompat.id: "syncToPlaybackCheckBox"

                            Navigation.parentItem: rootPlayer
                            Navigation.upItem: audioControls
                            Navigation.downItem: Player.isInteractive ? toggleControlBarButton : controlBar
                        }
                    }

                    Widgets.SubtitleLabel {
                        id: labelVolume

                        anchors.right: parent.right
                        anchors.top: parent.top

                        anchors.rightMargin: VLCStyle.margin_normal
                        anchors.topMargin: VLCStyle.margin_xxsmall

                        visible: false

                        text: qsTr("Volume %1%").arg(Math.round(Player.volume * 100))

                        color: centerTheme.fg.primary

                        font.weight: Font.Normal

                        Connections {
                            target: Player

                            function onVolumeChanged() {
                                animationVolume.restart()
                            }
                        }

                        SequentialAnimation {
                            id: animationVolume

                            PropertyAction { target: labelVolume; property: "visible"; value: true }

                            PauseAnimation { duration: VLCStyle.duration_humanMoment }

                            PropertyAction { target: labelVolume; property: "visible"; value: false }
                        }
                    }

                }
            }
        }
    }

    Loader {
        id: libraryPanelLoader

        anchors {
            top: topBar.bottom
            bottom: controlBar.top
            left: parent.left
        }

        z: 1

        active: MainCtx.libraryPanel.visible && (MainCtx.intfMainWindow.visibility !== Window.FullScreen)

        source: "qrc:///qt/qml/VLC/MainInterface/LibraryPanel.qml"

        // The controls stay visible while the library is open.
        onLoaded: {
            item.maximumWidth = Qt.binding(() => rootPlayer.width / 2)
            rootPlayer.lockUnlockAutoHide(true)
        }

        onActiveChanged: {
            if (!active)
                rootPlayer.lockUnlockAutoHide(false)
        }
    }

    Binding {
        target: playerSpecializationLoader
        property: "anchors.leftMargin"
        value: libraryPanelLoader.active ? libraryPanelLoader.width : 0
    }

    TopBar {
        id: topBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1

        topMargin: VLCStyle.applicationVerticalMargin
        sideMargin: VLCStyle.applicationHorizontalMargin

        // NOTE: With pinned controls, the top controls are hidden when switching to
        //       fullScreen.
        visible: (MainCtx.pinVideoControls === false
                  ||
                  MainCtx.intfMainWindow.visibility !== Window.FullScreen)

        focus: true
        title: Player.title

        pinControls: MainCtx.pinVideoControls
        overVideo: MainCtx.hasEmbededVideo && !rootPlayer._controlsUnderVideo

        showCSD: MainCtx.clientSideDecoration && (MainCtx.intfMainWindow.visibility !== Window.FullScreen)
        showToolbar: MainCtx.hasToolbarMenu && (MainCtx.intfMainWindow.visibility !== Window.FullScreen)
        playlistVisible: playlistVisibility.isPlaylistVisible

        plListView: {
            if (playlistpopup.active)
                return playlistpopup.item?.playlistView ?? null
            else if (playlistWindowLoader?.status === Loader.Ready)
                return playlistWindowLoader.item.playlistView
            else
                return null
        }

        Navigation.parentItem: rootPlayer
        Navigation.downItem: {
            if (playlistVisibility.isPlaylistVisible)
                return playlistpopup
            if (MainCtx.hasEmbededVideo)
                return playerSpecializationLoader
            if (Player.isInteractive)
                return toggleControlBarButton
            return controlBar
        }

        //initial state value is "", using a binding avoid animation on startup
        Binding on state {
            when: playerToolbarVisibilityFSM.started
            value: (playerToolbarVisibilityFSM.isVisible || rootPlayer._controlsUnderVideo) ? "visible" : "hidden"
        }

        onTogglePlaylistVisibility: playlistVisibility.togglePlaylistVisibility()

        onRequestLockUnlockAutoHide: (lock) => {
            rootPlayer.lockUnlockAutoHide(lock)
        }

        onBackRequested: {
            if (MainCtx.hasEmbededVideo && !MainCtx.canShowVideoPIP) {
               MainPlaylistController.stop()
            }
            MainCtx.playerView = false
        }

        sidebarVisible: MainCtx.libraryPanel?.visible ?? false

        onToggleSidebar: {
            if (MainCtx.libraryPanel)
                MainCtx.libraryPanel.visible = !MainCtx.libraryPanel.visible
            else
                backRequested()
        }

        onFolderClicked: backRequested()

        FadeControllerStateGroup {
            target: topBar
        }
    }

    ResumeDialog {
        id: resumeDialog

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: controlBar.top
        anchors.bottomMargin: VLCStyle.margin_large

        width: Math.min(implicitWidth, parent.width - 2 * VLCStyle.margin_large)

        z: 2

        colorContext.palette: windowTheme.palette

        Navigation.parentItem: rootPlayer
        Navigation.downItem: controlBar

        onHidden: {
            if (activeFocus)
                controlBar.forceActiveFocus()
        }

        onVisibleChanged: rootPlayer.lockUnlockAutoHide(visible)
    }

    Loader {
        id: playlistpopup

        anchors {
            top: topBar.visible ? topBar.bottom : parent.top
            right: parent.right
            bottom: parent.bottom

            topMargin: VLCStyle.dp(20, VLCStyle.scale)
            rightMargin: VLCStyle.applicationHorizontalMargin + VLCStyle.dp(20, VLCStyle.scale)
            bottomMargin: parent.height - rootPlayer.positionSliderY + VLCStyle.dp(20, VLCStyle.scale)
        }

        width: implicitWidth

        z: 1

        focus: false

        active: MainCtx.playqueuePanel.docked

        //initial state value is "", using a binding avoid animation on startup
        Binding on state {
            when: playlistVisibility.started
            value: (status === Loader.Ready && playlistVisibility.isPlaylistVisible) ? "expanded" : "retracted"
        }

        Component.onCompleted: {
            Qt.callLater(() => { playlistTransition.enabled = true; })
        }

        states: [
            State {
                name: "expanded"
                PropertyChanges {
                    target: playlistpopup
                    opacity: 1.0
                    visible: true
                }
           }, State {
                name: "retracted"
                PropertyChanges {
                    target: playlistpopup
                    opacity: 0.0
                    visible: false
                }
           }
        ]

        transitions: Transition {
            id: playlistTransition
            enabled: false

            from: "retracted"; to: "expanded";
            reversible: true

            SequentialAnimation {
                PropertyAction { property: "visible" }

                NumberAnimation {
                    property: "opacity"
                    duration: VLCStyle.duration_short
                    easing.type: Easing.InOutSine
                }
            }
        }

        sourceComponent: QueuePanel {
            id: queuePanel

            property real minimumWidth: Math.max(VLCStyle.dp(400, VLCStyle.scale), playlistView.minimumWidth)
            property real maximumWidth: rootPlayer.width / 2

            implicitWidth: Helpers.clamp(MainCtx.playqueuePanel.width
                                 , queuePanel.minimumWidth
                                 , Math.max(queuePanel.minimumWidth, queuePanel.maximumWidth))
            height: playlistpopup.height

            focus: true

            playlistView.view.fadingEdge.pixelAlignedForDPR: !controlBar.visible

            Navigation.parentItem: rootPlayer
            Navigation.upItem: topBar
            Navigation.downItem: Player.isInteractive ? toggleControlBarButton : controlBar
            Navigation.leftAction: closePlaylist
            Navigation.cancelAction: closePlaylist

            function closePlaylist() {
                playlistVisibility.togglePlaylistVisibility()
                controlBar.forceActiveFocus()
            }

            Widgets.HorizontalResizeHandle {
                id: resizeHandle

                property bool _inhibitMainCtxUpdate: false

                parent: queuePanel

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                atRight: false
                currentWidth: playlistpopup.width

                maximumWidth: queuePanel.maximumWidth
                minimumWidth: queuePanel.minimumWidth

                onRequestedWidthChanged: {
                    if (!_inhibitMainCtxUpdate)
                        MainCtx.playqueuePanel.width = requestedWidth
                }

                Component.onCompleted:  _updateFromMainCtx()

                function _updateFromMainCtx() {
                    if (requestedWidth === MainCtx.playqueuePanel.width)
                        return

                    _inhibitMainCtxUpdate = true
                    requestedWidth = MainCtx.playqueuePanel.width
                    _inhibitMainCtxUpdate = false
                }

                Connections {
                    target: MainCtx.playqueuePanel

                    function onWidthChanged() {
                        resizeHandle._updateFromMainCtx()
                    }
                }
            }
        }
    }

    // the player settings take the place of the play queue panel
    Loader {
        id: playerSettingsLoader

        anchors {
            top: topBar.visible ? topBar.bottom : parent.top
            right: parent.right
            bottom: parent.bottom

            topMargin: VLCStyle.dp(20, VLCStyle.scale)
            rightMargin: VLCStyle.applicationHorizontalMargin + VLCStyle.dp(20, VLCStyle.scale)
            bottomMargin: parent.height - rootPlayer.positionSliderY + VLCStyle.dp(20, VLCStyle.scale)
        }

        z: 1

        active: MainCtx.playerSettingsVisible

        onActiveChanged: {
            if (active)
                MainCtx.playqueuePanel.visible = false
            rootPlayer.lockUnlockAutoHide(active)
        }

        Connections {
            target: MainCtx.playqueuePanel

            function onVisibleChanged() {
                if (MainCtx.playqueuePanel.visible)
                    MainCtx.playerSettingsVisible = false
            }
        }

        sourceComponent: PlayerSettingsPanel {
            focus: true

            onCloseRequested: {
                MainCtx.playerSettingsVisible = false
                controlBar.forceActiveFocus()
            }
        }
    }

    Dialogs {
        z: 10
        bgContent: rootPlayer

        anchors {
            bottom: controlBar.visible ? controlBar.top : rootPlayer.bottom
            left: parent.left
            right: parent.right

            bottomMargin: (rootPlayer._controlsUnderVideo || !controlBar.visible)
                          ? 0 : - VLCStyle.margin_large
        }
    }

    Timer {
        // NavigationBox's visibility depends on this timer
        id: interactiveAutoHideTimer
        running: false
        repeat: false
        interval: 3000
    }

    NavigationBox {
        id: navBox
        visible: Player.isInteractive && navBox.show
                    && (interactiveAutoHideTimer.running
                    || navBox.hovered || !MainCtx.hasEmbededVideo)

        x: rootPlayer.x + VLCStyle.margin_normal + VLCStyle.applicationHorizontalMargin
        y: controlBar.y - navBox.height - VLCStyle.margin_normal

        dragXMin: 0
        dragXMax: rootPlayer.width - navBox.width
        dragYMin: 0
        dragYMax: rootPlayer.height - navBox.height

        Drag.onDragStarted: (controlId) => {
            navBox.x = drag.x
            navBox.y = drag.y
        }
    }

    Connections {
        target: MainCtx
        function onNavBoxToggled() { interactiveAutoHideTimer.restart() }
    }

    Connections {
        target: rootPlayer
        function onWidthChanged() {
            if (navBox.x > navBox.dragXMax)
                navBox.x = navBox.dragXMax
        }
        function onHeightChanged() {
            if (navBox.y > navBox.dragYMax)
                navBox.y = navBox.dragYMax
        }
    }

    Widgets.ButtonExt {
        id: toggleControlBarButton
        visible: Player.isInteractive
                 && MainCtx.hasEmbededVideo
                 && !(MainCtx.pinVideoControls && !Player.fullscreen)
                 && (interactiveAutoHideTimer.running === true
                     || controlBar.state !== "hidden" || toggleControlBarButton.hovered)
        focus: true
        anchors {
            bottom: controlBar.state === "hidden" ? parent.bottom : controlBar.top
            horizontalCenter: parent.horizontalCenter
        }
        iconSize: VLCStyle.icon_large
        iconTxt: controlBar.state === "hidden" ? VLCIcons.expand_inverted : VLCIcons.expand

        Navigation.parentItem: rootPlayer
        Navigation.upItem: playlistVisibility.isPlaylistVisible ? playlistpopup : (MainCtx.hasEmbededVideo ? playerSpecializationLoader : topBar)
        Navigation.downItem: controlBar

        onClicked:{
            playerToolbarVisibilityFSM.askShow();
        }
    }

    Widgets.FloatingNotification {
        id: notif

        anchors {
            bottom: controlBar.top
            left: parent.left
            right: parent.right
            margins: VLCStyle.margin_large
        }
    }

    ControlBar {
        id: controlBar

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        hoverEnabled: true

        focus: true

        rightPadding: VLCStyle.applicationHorizontalMargin + (inlinePosition ? VLCStyle.dp(20, VLCStyle.scale) : 0)
        leftPadding: rightPadding
        bottomPadding: VLCStyle.applicationVerticalMargin + (inlinePosition ? VLCStyle.dp(11, VLCStyle.scale)
                                                                             : VLCStyle.margin_xsmall)

        textPosition: (MainCtx.pinVideoControls)
                      ? ControlBar.TimeTextPosition.LeftRightSlider
                      : ControlBar.TimeTextPosition.AboveSlider

        // hide right text so that it won't overlap with play queue
        showRemainingTime: (textPosition !== ControlBar.TimeTextPosition.AboveSlider)
                           || !playlistVisibility.isPlaylistVisible

        onStateChanged: {
            if (state === "visible")
                showChapterMarks()
        }

        Navigation.parentItem: rootPlayer
        Navigation.upItem: {
            if (playlistVisibility.isPlaylistVisible)
                return playlistpopup
            if (Player.isInteractive)
                return toggleControlBarButton
            if (!MainCtx.hasEmbededVideo)
                return playerSpecializationLoader
            return topBar
        }

        //initial state value is "", using a binding avoid animation on startup
        Binding on state {
            when: playerToolbarVisibilityFSM.started
            value: (playerToolbarVisibilityFSM.isVisible || rootPlayer._controlsUnderVideo) ? "visible" : "hidden"
        }

        onRequestLockUnlockAutoHide: (lock) => rootPlayer.lockUnlockAutoHide(lock)

        identifier: (Player.hasVideoOutput) ? PlayerControlbarModel.Videoplayer
                                            : PlayerControlbarModel.Audioplayer

        onHoveredChanged: rootPlayer.lockUnlockAutoHide(hovered)

        FadeControllerStateGroup {
            target: controlBar
        }
    }

    QmlAudioContextMenu {
        id: audioContextMenu

        ctx: MainCtx
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: !MainCtx.hasEmbededVideo

        onTapped: (eventPoint, button) => {
            if (button & Qt.RightButton) {
                audioContextMenu.popup(eventPoint.globalPosition)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        propagateComposedEvents: true
        cursorShape: undefined
        onClicked: {
            MainCtx.playerView = false
        }
    }

    //filter key events to keep toolbar
    //visible when user navigates within the control bar
    KeyEventFilter {
    id: filter
    target: MainCtx.intfMainWindow

        Keys.onPressed: (event) => {
            if (Player.isInteractive)
                interactiveAutoHideTimer.restart()
            else
                playerToolbarVisibilityFSM.keyboardMove()
        }
    }
}
