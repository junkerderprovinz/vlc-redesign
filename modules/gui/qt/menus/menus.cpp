/*****************************************************************************
 * menus.cpp : Qt menus
 *****************************************************************************
 * Copyright © 2006-2011 the VideoLAN team
 *
 * Authors: Clément Stenac <zorglub@videolan.org>
 *          Jean-Baptiste Kempf <jb@videolan.org>
 *          Jean-Philippe André <jpeg@videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

/** \todo
 * - Remove static currentGroup
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_intf_strings.h>
#include <vlc_aout.h>                             /* audio_output_t */
#include <vlc_interface.h>
#include <vlc_actions.h>

#include "menus.hpp"
#include "menu_style.hpp"

#include "maininterface/mainctx.hpp"                     /* View modifications */
#include "maininterface/mainctx_submodels.hpp"
#include "dialogs/dialogs_provider.hpp"                   /* Dialogs display */
#include "dialogs/help/help.hpp"
#include "player/player_controller.hpp"                      /* Input Management */
#include "playlist/playlist_controller.hpp"
#include "dialogs/extensions/extensions_manager.hpp"                 /* Extensions menu */
#include "dialogs/extended/extended_panels.hpp"
#include "dialogs/systray/systray.hpp"
#include "util/varchoicemodel.hpp"
#include "util/color_scheme_model.hpp"
#include "util/colorizedsvgicon.hpp"
#include "util/vlchotkeyconverter.hpp"
#include "dialogs/toolbar/controlbar_profile_model.hpp"
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlrecentmediamodel.hpp"
#include "medialibrary/mlbookmarkmodel.hpp"


#include <QMenu>
#include <QMenuBar>
#include <QAction>
#include <QActionGroup>
#include <QSignalMapper>

#include <algorithm>

using namespace vlc::playlist;

/*
  This file defines the main menus and the pop-up menu (right-click menu)
  and the systray menu (in that order in the file)

  There are 4 menus that have to be rebuilt every time there are called:
  Audio, Video, Navigation, view
  4 functions are building those menus: AudioMenu, VideoMenu, NavigMenu, View

  */

RendererMenu *VLCMenuBar::rendererMenu = NULL;

/**
 * @brief Add static entries to DP in menus
 **/
template<typename Functor>
QAction *addDPStaticEntry( QMenu *menu,
                       const QString& text,
                       const char *icon,
                       const Functor member,
                       const char *shortcut = NULL,
                       QAction::MenuRole role = QAction::NoRole
                       )
{
    QAction *action = NULL;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ), text, THEDP, member );
    }
    else
#endif
    {
        action = menu->addAction( text, THEDP, member );
    }
    if( !EMPTY_STR( shortcut ) )
        action->setShortcut( qfut( shortcut ) );
#ifdef __APPLE__
    action->setMenuRole( role );
#else
    Q_UNUSED( role );
#endif
    return action;
}

/**
 * @brief Add static entries to MIM in menus
 **/
template<typename Fun>
static QAction* addMIMStaticEntry( qt_intf_t *p_intf,
                            QMenu *menu,
                            const QString& text,
                            const char *icon,
                            Fun member )
{
    QAction *action;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( text, THEMIM,  member );
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ) );
    }
    else
#endif
    {
        action = menu->addAction( text, THEMIM, member );
    }
    return action;
}

template<typename Fun>
static QAction* addMPLStaticEntry( qt_intf_t *p_intf,
                            QMenu *menu,
                            const QString& text,
                            const char *icon,
                            Fun member )
{
    QAction *action;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( text, THEMPL,  member );
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ) );
    }
    else
#endif
    {
        action = menu->addAction( text, THEMPL, member );
    }
    return action;
}

/**
 * Two-tone icon drawn in the text and accent colors. Without the main
 * interface, the classic icon is used.
 **/
static QIcon entryIcon( qt_intf_t *p_intf, const QMenu *menu, const char *name,
                        const char *legacyIcon = nullptr )
{
#ifdef __APPLE__ /* We don't set icons in menus in MacOS X */
    Q_UNUSED( p_intf ); Q_UNUSED( menu ); Q_UNUSED( name ); Q_UNUSED( legacyIcon );
    return QIcon();
#else
    if( p_intf->p_mi )
        return MenuStyle::icon( QStringLiteral( ":/icons/figma/%1.svg" ).arg( QLatin1String( name ) ),
                                menu->palette().text().color(), p_intf->p_mi->accentColor() );
    if( !EMPTY_STR( legacyIcon ) )
        return ColorizedSvgIcon::colorizedIconForWidget( legacyIcon, menu );
    return QIcon();
#endif
}

/**
 * The first key bound to a core hotkey, as a shortcut hint for a menu entry.
 * It is only displayed: the core handles the key itself.
 **/
static QString hotkeyHint( qt_intf_t *p_intf, const char *option )
{
    char *keys = var_InheritString( p_intf, option );
    if( keys == NULL )
        return QString();
    const QString first = qfu( keys ).section( '\t', 0, 0 );
    free( keys );
    if( first.isEmpty() )
        return QString();
    QString hint = VLCKeyToString( vlc_str2keycode( qtu( first ) ), true );
    /* letter keys are named in lower case, keyboards show them in upper case */
    if( hint.size() - hint.lastIndexOf( QLatin1Char( '+' ) ) == 2 )
        hint.back() = hint.back().toUpper();
    return QLatin1Char( '\t' ) + hint;
}

static void addRecentMenu( qt_intf_t *p_intf, QMenu *menu, const QString &title )
{
    MainCtx *mi = p_intf->p_mi;
    if( !mi || !var_InheritBool( p_intf, "save-recentplay" ) || !mi->hasMediaLibrary() )
        return;

    MLRecentMediaModel* recentModel = new MLRecentMediaModel(nullptr);
    recentModel->setMl(mi->getMediaLibrary());
    recentModel->setLimit(10);
    QMenu* recentsMenu = new RecentMenu(recentModel, mi->getMediaLibrary(), menu);
    recentsMenu->setTitle( title );
    recentModel->setParent(recentsMenu);
    QAction *action = menu->addMenu( recentsMenu );
    action->setIcon( entryIcon( p_intf, menu, "recent-duo" ) );
}

/*****************************************************************************
 * All normal menus
 * Simple Code
 *****************************************************************************/

/**
 * Main Menu Bar Creation
 **/
VLCMenuBar::VLCMenuBar(QObject* parent)
    : QObject(parent)
{}


/**
 * Media ( File ) Menu
 * Opening, streaming and quit
 **/
void VLCMenuBar::FileMenu(qt_intf_t *p_intf, QMenu *menu)
{
    auto mi = p_intf->p_mi;
    QAction *action;

    //use a lambda here as the Triggrered signal is emiting and it will pass false (checked) as a first argument
    addDPStaticEntry( menu, qtr( "Open &File..." ),
        ":/menu/file.svg", []() { THEDP->simpleOpenDialog(); } , "Ctrl+O" );
    addDPStaticEntry( menu, qtr( "&Open Multiple Files..." ),
        ":/menu/file.svg", &DialogsProvider::openFileDialog, "Ctrl+Shift+O" );
    addDPStaticEntry( menu, qfut( I_OP_OPDIR ),
        ":/menu/folder.svg", &DialogsProvider::PLOpenDir, "Ctrl+F" );
    addDPStaticEntry( menu, qtr( "Open &Disc..." ),
        ":/menu/disc.svg", &DialogsProvider::openDiscDialog, "Ctrl+D" );
    addDPStaticEntry( menu, qtr( "Open &Network Stream..." ),
        ":/menu/network.svg", &DialogsProvider::openNetDialog, "Ctrl+N" );
    addDPStaticEntry( menu, qtr( "Open &Capture Device..." ),
        ":/menu/capture-card.svg", &DialogsProvider::openCaptureDialog, "Ctrl+C" );

    addDPStaticEntry( menu, qtr( "Open &Location from clipboard" ),
                      NULL, &DialogsProvider::openUrlDialog, "Ctrl+V" );

    addRecentMenu( p_intf, menu, qtr( "Open &Recent Media" ) );

    menu->addSeparator();

    addDPStaticEntry( menu, qfut( I_PL_SAVE ), "", &DialogsProvider::savePlayingToPlaylist,
        "Ctrl+Y" );

    addDPStaticEntry( menu, qtr( "Conve&rt / Save..." ), "",
        &DialogsProvider::openAndTranscodingDialogs, "Ctrl+R" );
    addDPStaticEntry( menu, qtr( "&Stream..." ),
        ":/menu/stream.svg", &DialogsProvider::openAndStreamingDialogs, "Ctrl+S" );
    menu->addSeparator();

    action = menu->addAction( qtr( "Quit at the end of play queue" ), [playlist = THEMPL](bool checked){
        if (checked)
            playlist->setMediaStopAction(PlaylistController::MEDIA_STOPPED_EXIT);
        else
            playlist->setMediaStopAction(PlaylistController::MEDIA_STOPPED_CONTINUE);
    });
    action->setCheckable( true );
    action->setChecked( THEMPL->getMediaStopAction() ==  PlaylistController::MEDIA_STOPPED_EXIT);

    VLCSystray* systray = mi ? mi->getSysTray() : nullptr;
    if( systray )
    {
        action = menu->addAction( qtr( "Close to systray"), systray,
                                 &VLCSystray::toggleUpdateMenu );
    }

    addDPStaticEntry( menu, qtr( "&Quit" ) ,
        ":/menu/exit.svg", &DialogsProvider::quit, "Ctrl+Q" );
}

/**
 * Tools, like Media Information, Preferences or Messages
 **/
void VLCMenuBar::ToolsMenu( qt_intf_t *p_intf, QMenu *menu )
{
    addDPStaticEntry( menu, qtr( "&Effects and Filters"), ":/menu/ic_fluent_options.svg",
            &DialogsProvider::extendedDialog, "Ctrl+E" );

    addDPStaticEntry( menu, qtr( "&Track Synchronization"), ":/menu/ic_fluent_options.svg",
            &DialogsProvider::synchroDialog, "" );

    addDPStaticEntry( menu, qfut( I_MENU_INFO ) , ":/menu/info.svg",
        QOverload<>::of(&DialogsProvider::mediaInfoDialog), "Ctrl+I" );

    addDPStaticEntry( menu, qfut( I_MENU_CODECINFO ) ,
        ":/menu/info.svg", &DialogsProvider::mediaCodecDialog, "Ctrl+J" );

#ifdef ENABLE_VLM
    addDPStaticEntry( menu, qfut( I_MENU_VLM ), "", &DialogsProvider::vlmDialog,
        "Ctrl+Shift+W" );
#endif

    addDPStaticEntry( menu, qtr( "Program Guide" ), "", &DialogsProvider::epgDialog,
        "" );

    addDPStaticEntry( menu, qfut( I_MENU_MSG ),
        ":/menu/messages.svg", &DialogsProvider::messagesDialog, "Ctrl+M" );

    addDPStaticEntry( menu, qtr( "Plu&gins and extensions" ),
        "", &DialogsProvider::pluginDialog );
    menu->addSeparator();

    if( !p_intf->b_isDialogProvider )
    {
        addDPStaticEntry( menu, qtr( "Customize &Player..." ),
            ":/menu/preferences.svg", &DialogsProvider::showToolbarEditorDialog);
        addDPStaticEntry( menu, qtr( "&Keyboard Shortcuts..." ),
            "", &DialogsProvider::keyboardShortcutsDialog );
    }

    addDPStaticEntry( menu, qtr( "&Global Settings..." ),
        ":/menu/preferences.svg", &DialogsProvider::prefsDialog, "Ctrl+P", QAction::PreferencesRole );
}

/**
 * View Menu
 * Interface modification, load other interfaces, activate Extensions
 * \param current, set to NULL for menu creation, else for menu update
 **/
void VLCMenuBar::ViewMenu(qt_intf_t *p_intf, QMenu *menu)
{
    QAction *action;

    MainCtx *mi = p_intf->p_mi;
    assert( mi );
    assert(menu);

    //menu->clear();
    //HACK menu->clear() does not delete submenus
    QList<QAction*> actions = menu->actions();
    foreach( QAction *a, actions )
    {
        QMenu *m = a->menu();
        if( a->parent() == menu ) delete a;
        else menu->removeAction( a );
        if( m && m->parent() == menu ) delete m;
    }

    action = menu->addAction(
#ifndef __APPLE__
            ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_playlist.svg", menu ),
#endif
            qtr( "Play &Queue" ));
    action->setShortcut(QString( "Ctrl+L" ));
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi->getPlayqueuePanel(), &SidePanelCtx::setVisible );
    action->setChecked( mi->getPlayqueuePanel()->isVisible() );

    /* Docked Play Queue */
    action = menu->addAction( qtr( "Docked Play Queue" ) );
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi->getPlayqueuePanel(), &SidePanelCtx::setDocked );
    action->setChecked( mi->getPlayqueuePanel()->isDocked() );

    /* Library beside the player */
    action = menu->addAction( qtr( "&Library Panel" ) );
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi->getLibraryPanel(), &SidePanelCtx::setVisible );
    action->setChecked( mi->getLibraryPanel()->isVisible() );

    menu->addSeparator();

    action = menu->addAction( qtr( "Always on &top" ) );
    action->setCheckable( true );
    action->setChecked( mi->isInterfaceAlwaysOnTop() );
    connect( action, &QAction::triggered, mi, &MainCtx::setInterfaceAlwaysOnTop );

    menu->addSeparator();

    {
        bool isPlayerVisible = mi->getMainInterfaceModes() & MainCtx::MAININTERFACE_MODE_PLAYER;
        action = menu->addAction(qtr("&Big Player View"));
        action->setCheckable( true );
        action->setChecked( isPlayerVisible );
        connect( action, &QAction::triggered, mi, &MainCtx::setPlayerView);
    }

    /* FullScreen View */
    action = menu->addAction( qtr( "&Fullscreen Interface" ), mi,
            &MainCtx::toggleInterfaceFullScreen );
    action->setShortcut( QString( "F11" ) );
    action->setCheckable( true );
    action->setChecked( mi->interfaceVisibility() == QWindow::FullScreen );

    /*Minimal View*/
    action = menu->addAction( qtr( "&Minimal View" ) );
    action->setShortcut(QString( "Ctrl+H" ));
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi, &MainCtx::setMinimalView );
    action->setChecked( mi->isMinimalView() );

    action = menu->addAction( qtr( "&View Items as Grid" ), mi,
            &MainCtx::setGridView );
    action->setCheckable( true );
    action->setChecked( mi->hasGridView() );

    /* The model lists the system scheme first, the menu lists it last */
    ColorSchemeModel *colorScheme = mi->getColorScheme();
    const QVector<ColorSchemeModel::Item> schemes = colorScheme->getSchemes();
    QMenu *themeMenu = menu->addMenu( qtr( "&Theme" ) );
    QActionGroup *themeGroup = new QActionGroup( themeMenu );
    for( const ColorSchemeModel::ColorScheme scheme :
         { ColorSchemeModel::Day, ColorSchemeModel::Night, ColorSchemeModel::System } )
    {
        const auto item = std::find_if( schemes.cbegin(), schemes.cend(),
            [scheme]( const ColorSchemeModel::Item &i ) { return i.scheme == scheme; } );
        const int row = item - schemes.cbegin();
        action = themeMenu->addAction( item->text );
        action->setCheckable( true );
        action->setChecked( row == colorScheme->currentIndex() );
        action->setActionGroup( themeGroup );
        connect( action, &QAction::triggered, colorScheme, [colorScheme, row]() {
            colorScheme->setCurrentIndex( row );
        });
    }

    menu->addSeparator();

    InterfacesMenu( p_intf, menu );
    menu->addSeparator();

    /* Extensions */
    ExtensionsMenu( p_intf, menu );
}

/**
 * Interface Sub-Menu, to list extras interface and skins
 **/
void VLCMenuBar::InterfacesMenu( qt_intf_t *p_intf, QMenu *current )
{
    assert(current);
    VLCVarChoiceModel* model = new VLCVarChoiceModel(VLC_OBJECT(p_intf->intf), "intf-add", current);
    CheckableListMenu* submenu = new CheckableListMenu(qtr("Interfaces"), model, QActionGroup::ExclusionPolicy::None, current);
    current->addMenu(submenu);
}

/**
 * Extensions menu: populate the current menu with extensions
 **/
void VLCMenuBar::ExtensionsMenu( qt_intf_t *p_intf, QMenu *extMenu )
{
    /* Get ExtensionsManager and load extensions if needed */
    ExtensionsManager *extMgr = ExtensionsManager::getInstance( p_intf );

    if( !var_InheritBool( p_intf, "qt-autoload-extensions")
        && !extMgr->isLoaded() )
    {
        return;
    }

    if( !extMgr->isLoaded() && !extMgr->cannotLoad() )
    {
        extMgr->loadExtensions();
    }

    /* Let the ExtensionsManager build itself the menu */
    extMenu->addSeparator();
    extMgr->menu( extMenu );
}

void VLCMenuBar::VolumeEntries( qt_intf_t *p_intf, QMenu *current )
{
    current->addSeparator();

    current->addAction( QIcon( ":/menu/volume-high.svg" ), qtr( "&Increase Volume" ), THEMIM, &PlayerController::setVolumeUp );
    current->addAction( QIcon( ":/menu/volume-low.svg" ), qtr( "&Decrease Volume" ), THEMIM, &PlayerController::setVolumeDown );
    current->addAction( QIcon( ":/menu/volume-muted.svg" ), qtr( "&Mute" ), THEMIM, &PlayerController::toggleMuted );
}

/**
 * Main Audio Menu
 **/
void VLCMenuBar::AudioMenu( qt_intf_t *p_intf, QMenu * current )
{
    if( current->isEmpty() )
    {
        current->addMenu(new CheckableListMenu(qtr( "Audio &Track" ), THEMIM->getAudioTracks(), QActionGroup::ExclusionPolicy::ExclusiveOptional, current));

        current->addMenu(new CheckableListMenu(qtr( "&Audio Device" ), THEMIM->getAudioDevices(), QActionGroup::ExclusionPolicy::Exclusive, current));

        VLCVarChoiceModel *mix_mode = THEMIM->getAudioMixMode();
        if (mix_mode->rowCount() == 0)
            current->addMenu( new CheckableListMenu(qtr( "&Stereo Mode" ), THEMIM->getAudioStereoMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        else
            current->addMenu( new CheckableListMenu(qtr( "&Mix Mode" ), mix_mode, QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addSeparator();

        current->addMenu( new CheckableListMenu(qtr( "&Visualizations" ), THEMIM->getAudioVisualizations(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        VolumeEntries( p_intf, current );
    }
}

/* Subtitles */
void VLCMenuBar::SubtitleMenu( qt_intf_t *p_intf, QMenu *current, bool b_popup )
{
    if( current->isEmpty() || b_popup )
    {
        addDPStaticEntry( current, qtr( "Add &Subtitle File..." ), "",
                &DialogsProvider::loadSubtitlesFile);
        current->addMenu(new CheckableListMenu(qtr( "Sub &Track" ), THEMIM->getSubtitleTracks(), QActionGroup::ExclusionPolicy::ExclusiveOptional, current));
        current->addSeparator();
    }
}

/**
 * Main Video Menu
 * Subtitles are part of Video.
 **/
void VLCMenuBar::VideoMenu( qt_intf_t *p_intf, QMenu *current )
{
    if( current->isEmpty() )
    {
        current->addMenu(new CheckableListMenu(qtr( "Video &Track" ), THEMIM->getVideoTracks(), QActionGroup::ExclusionPolicy::None, current));

        current->addSeparator();
        current->addMenu( new CheckableListMenu(qtr( "&3D Output" ), THEMIM->getVideoStereoMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Surface modifiers */
        current->addAction(new BooleanPropertyAction(qtr( "&Fullscreen"), THEMIM, "fullscreen", current));
        QAction* action = new BooleanPropertyAction(qtr( "Always Fit &Window"), THEMIM, "autoscale", current);
        action->setEnabled( THEMIM->hasVideoOutput() );
        connect(THEMIM, &PlayerController::hasVideoOutputChanged, action, &QAction::setEnabled);
        current->addAction(action);
        current->addAction(new BooleanPropertyAction(qtr( "Set as Wall&paper"), THEMIM, "wallpaperMode", current));

        current->addSeparator();
        /* Size modifiers */
        current->addMenu( new CheckableListMenu(qtr( "&Zoom" ), THEMIM->getZoom(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Aspect Ratio" ), THEMIM->getAspectRatio(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Crop" ), THEMIM->getCrop(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Fit" ), THEMIM->getFit(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Rendering modifiers */
        current->addMenu( new CheckableListMenu(qtr( "&Deinterlace" ), THEMIM->getDeinterlace(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Deinterlace mode" ), THEMIM->getDeinterlaceMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Other actions */
        QAction* snapshotAction = new QAction(qtr( "Take &Snapshot" ), current);
        connect(snapshotAction, &QAction::triggered, THEMIM, &PlayerController::snapshot);
        current->addAction(snapshotAction);
    }
}

/**
 * Navigation Menu
 * For DVD, MP4, MOV and other chapter based format
 **/
void VLCMenuBar::NavigMenu( qt_intf_t *p_intf, QMenu *menu )
{
    QAction *action;
    QMenu *submenu;

    menu->addMenu( new CheckableListMenu( qtr( "T&itle" ), THEMIM->getTitles(), QActionGroup::ExclusionPolicy::Exclusive, menu) );
    submenu = new CheckableListMenu( qtr( "&Chapter" ), THEMIM->getChapters(), QActionGroup::ExclusionPolicy::Exclusive, menu );
    submenu->setTearOffEnabled( true );
    menu->addMenu( submenu );
    menu->addMenu( new CheckableListMenu( qtr("&Program") , THEMIM->getPrograms(), QActionGroup::ExclusionPolicy::Exclusive, menu) );

    MainCtx * mi = p_intf->p_mi;

    if (mi && p_intf->p_mi->hasMediaLibrary() )
    {
        MediaLib * mediaLib = mi->getMediaLibrary();

        BookmarkMenu * bookmarks = new BookmarkMenu(mediaLib, p_intf->p_player, menu);

        bookmarks->setTitle(qfut(I_MENU_BOOKMARK));

        action = menu->addMenu(bookmarks);

        action->setData("bookmark");
    }

    menu->addSeparator();

    if ( !VLCMenuBar::rendererMenu )
        VLCMenuBar::rendererMenu = new RendererMenu( NULL, p_intf, p_intf->p_mainPlayerController );

    menu->addMenu( VLCMenuBar::rendererMenu );
    menu->addSeparator();


    PopupMenuControlEntries( menu, p_intf );

    RebuildNavigMenu( p_intf, menu );
}

void VLCMenuBar::RebuildNavigMenu( qt_intf_t *p_intf, QMenu *menu )
{
    QAction* action;

#define ADD_ACTION( title, slot, visibleSignal, visible ) \
    action = menu->addAction( title, THEMIM,  slot ); \
    if (! visible)\
        action->setVisible(false); \
    connect( THEMIM, visibleSignal, action, &QAction::setVisible );

    ADD_ACTION( qtr("Previous Title"), &PlayerController::titlePrev, &PlayerController::hasTitlesChanged, THEMIM->hasTitles() );
    ADD_ACTION( qtr("Next Title"), &PlayerController::titleNext, &PlayerController::hasTitlesChanged, THEMIM->hasTitles() );
    ADD_ACTION( qtr("Previous Chapter"), &PlayerController::chapterPrev, &PlayerController::hasChaptersChanged, THEMIM->hasChapters() );
    ADD_ACTION( qtr("Next Chapter"), &PlayerController::chapterNext, &PlayerController::hasChaptersChanged, THEMIM->hasChapters() );

#undef ADD_ACTION

    PopupMenuPlaylistEntries( menu, p_intf );
}

/**
 * Help/About Menu
**/
void VLCMenuBar::HelpMenu(qt_intf_t *p_intf, QMenu *menu )
{
    addDPStaticEntry( menu, qtr( "&Help" ) ,
        ":/menu/help.svg", &DialogsProvider::helpDialog, "F1" );
#ifdef UPDATE_CHECK
    addDPStaticEntry( menu, qtr( "Check for &Updates..." ) , "",
                     [ctx = QPointer(p_intf->p_mi)]() {
        if (Q_LIKELY(ctx))
        {
            const auto updateModel = ctx->getUpdateModel();
            assert(updateModel);
            updateModel->checkUpdate(true);
        }
    });
#endif
    menu->addSeparator();
    addDPStaticEntry( menu, qfut( I_MENU_ABOUT ), ":/menu/info.svg",
            &DialogsProvider::aboutDialog, "Shift+F1", QAction::AboutRole );
}

/*****************************************************************************
 * Popup menus - Right Click menus                                           *
 *****************************************************************************/

void VLCMenuBar::PopupMenuPlaylistEntries( QMenu *menu, qt_intf_t *p_intf )
{
    QAction *action;
    bool hasInput = THEMIM->hasInput();

    /* Play or Pause action and icon */
    if( !hasInput || THEMIM->getPlayingState() != PlayerController::PLAYING_STATE_PLAYING )
    {
        action = menu->addAction( qtr( "&Play" ) + hotkeyHint( p_intf, "key-play-pause" ), [p_intf]() {
            if ( THEMPL->isEmpty() )
                THEDP->openFileDialog();
            else
                THEMPL->togglePlayPause();
        });
        action->setIcon( entryIcon( p_intf, menu, "playback-duo", ":/menu/ic_fluent_play_filled.svg" ) );
    }
    else
    {
        action = addMPLStaticEntry( p_intf, menu, qtr( "Pause" ) + hotkeyHint( p_intf, "key-play-pause" ),
                ":/menu/ic_pause_filled.svg", &PlaylistController::togglePlayPause );
    }

    /* Stop */
    action = addMPLStaticEntry( p_intf, menu, qtr( "&Stop" ) + hotkeyHint( p_intf, "key-stop" ),
            "", &PlaylistController::stop );
    action->setIcon( entryIcon( p_intf, menu, "stop-duo", ":/menu/ic_fluent_stop.svg" ) );
    if( !hasInput )
        action->setEnabled( false );

    /* Next / Previous */
    bool bPlaylistEmpty = THEMPL->isEmpty();
    QAction* previousAction = addMPLStaticEntry( p_intf, menu, qtr( "Pre&vious" ) + hotkeyHint( p_intf, "key-prev" ),
            "", &PlaylistController::prev );
    previousAction->setIcon( entryIcon( p_intf, menu, "previous-duo", ":/menu/ic_fluent_previous.svg" ) );
    previousAction->setEnabled( !bPlaylistEmpty );
    connect( THEMPL, &PlaylistController::isEmptyChanged, previousAction, &QAction::setDisabled);

    QAction* nextAction = addMPLStaticEntry( p_intf, menu, qtr( "Ne&xt" ) + hotkeyHint( p_intf, "key-next" ),
            "", &PlaylistController::next );
    nextAction->setIcon( entryIcon( p_intf, menu, "next-duo", ":/menu/ic_fluent_next.svg" ) );
    nextAction->setEnabled( !bPlaylistEmpty );
    connect( THEMPL, &PlaylistController::isEmptyChanged, nextAction, &QAction::setDisabled);

    action = menu->addAction( qtr( "Record" ) + hotkeyHint( p_intf, "key-record" ),
                              THEMIM, &PlayerController::toggleRecord );
    action->setIcon( entryIcon( p_intf, menu, "record-duo", ":/menu/ic_fluent_record.svg" ) );
    if( !hasInput )
        action->setEnabled( false );
    menu->addSeparator();
}

void VLCMenuBar::PopupMenuControlEntries( QMenu *menu, qt_intf_t *p_intf,
                                        bool b_normal )
{
    QAction *action;
    QMenu *rateMenu = new QMenu( qtr( "Sp&eed" ), menu );
    rateMenu->setTearOffEnabled( true );

    if( b_normal )
    {
        /* Faster/Slower */
        action = rateMenu->addAction( qtr( "&Faster" ), THEMIM,
                                  &PlayerController::faster );
#ifndef __APPLE__ /* No icons in menus in Mac */
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_fast_forward.svg", rateMenu ) );
#endif
    }

    action = rateMenu->addAction( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_fast_forward.svg", rateMenu ), qtr( "Faster (fine)" ), THEMIM,
                              &PlayerController::littlefaster );

    action = rateMenu->addAction( qtr( "N&ormal Speed" ), THEMIM,
                              &PlayerController::normalRate );

    action = rateMenu->addAction( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_rewind.svg", rateMenu ), qtr( "Slower (fine)" ), THEMIM,
                              &PlayerController::littleslower );

    if( b_normal )
    {
        action = rateMenu->addAction( qtr( "Slo&wer" ), THEMIM,
                                  &PlayerController::slower );
#ifndef __APPLE__ /* No icons in menus in Mac */
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_rewind.svg", rateMenu ) );
#endif
    }

    action = menu->addMenu( rateMenu );

    menu->addSeparator();

    if( !b_normal ) return;

    action = menu->addAction( qtr( "&Jump Forward" ), THEMIM,
             &PlayerController::jumpFwd );
#ifndef __APPLE__ /* No icons in menus in Mac */
    action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_skip_forward_10.svg", menu ) );
#endif

    action = menu->addAction( qtr( "Jump Bac&kward" ), THEMIM,
             &PlayerController::jumpBwd );
#ifndef __APPLE__ /* No icons in menus in Mac */
    action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/menu/ic_fluent_skip_back_10.svg", menu ) );
#endif

    action = menu->addAction( qfut( I_MENU_GOTOTIME ), THEDP, &DialogsProvider::gotoTimeDialog );
    action->setShortcut( QKeySequence( "Ctrl+T" ) );

    menu->addSeparator();
}

void VLCMenuBar::PopupMenuStaticEntries( QMenu *menu )
{
    QMenu *openmenu = new QMenu( qtr( "Open Media" ), menu );
    addDPStaticEntry( openmenu, qfut( I_OP_OPF ),
        ":/menu/file.svg", &DialogsProvider::openFileDialog);
    addDPStaticEntry( openmenu, qfut( I_OP_OPDIR ),
        ":/menu/folder.svg", &DialogsProvider::PLOpenDir);
    addDPStaticEntry( openmenu, qtr( "Open &Disc..." ),
        ":/menu/disc.svg", &DialogsProvider::openDiscDialog);
    addDPStaticEntry( openmenu, qtr( "Open &Network..." ),
        ":/menu/network.svg", &DialogsProvider::openNetDialog);
    addDPStaticEntry( openmenu, qtr( "Open &Capture Device..." ),
        ":/menu/capture-card.svg", &DialogsProvider::openCaptureDialog);
    menu->addMenu( openmenu );

    menu->addSeparator();

    addDPStaticEntry( menu, qtr( "Quit" ), ":/menu/exit.svg",
                      &DialogsProvider::quit, "Ctrl+Q", QAction::QuitRole );
}

/**
 * Open entries of the application menu and of the right-click menu
 **/
void VLCMenuBar::OpenMediaEntries( qt_intf_t *p_intf, QMenu *menu )
{
    addDPStaticEntry( menu, qtr( "Open File(s)" ), "",
        []() { THEDP->simpleOpenDialog(); }, "Ctrl+O" )->setIcon( entryIcon( p_intf, menu, "file-duo" ) );
    addDPStaticEntry( menu, qtr( "Open Folder" ), "",
        &DialogsProvider::PLOpenDir, "Ctrl+F" )->setIcon( entryIcon( p_intf, menu, "folder-duo" ) );
    addDPStaticEntry( menu, qtr( "Open Network Stream" ), "",
        &DialogsProvider::openNetDialog, "Ctrl+N" )->setIcon( entryIcon( p_intf, menu, "streaming-duo" ) );
    addDPStaticEntry( menu, qtr( "Open Disc" ), "",
        &DialogsProvider::openDiscDialog, "Ctrl+D" )->setIcon( entryIcon( p_intf, menu, "disc-duo" ) );
    addDPStaticEntry( menu, qtr( "Open Capture Device" ), "",
        &DialogsProvider::openCaptureDialog, "Ctrl+C" )->setIcon( entryIcon( p_intf, menu, "capture-device-duo" ) );
}

/**
 * Shuffle, repeat and the play queue
 **/
void VLCMenuBar::PlaylistMenu( qt_intf_t *p_intf, QMenu *menu )
{
    MainCtx *mi = p_intf->p_mi;
    QAction *action;

    action = menu->addAction( qtr( "Shuffle" ) + hotkeyHint( p_intf, "key-random" ) );
    action->setCheckable( true );
    action->setChecked( THEMPL->isRandom() );
    connect( action, &QAction::triggered, THEMPL, &PlaylistController::setRandom );

    QActionGroup *repeatGroup = new QActionGroup( menu );
    const struct {
        QString text;
        PlaylistController::PlaybackRepeat mode;
    } repeatModes[] = {
        { qtr( "Repeat Off" ), PlaylistController::PLAYBACK_REPEAT_NONE },
        { qtr( "Repeat All" ), PlaylistController::PLAYBACK_REPEAT_ALL },
        { qtr( "Repeat One" ), PlaylistController::PLAYBACK_REPEAT_CURRENT },
    };
    for( const auto &repeat : repeatModes )
    {
        action = menu->addAction( repeat.text );
        action->setCheckable( true );
        action->setChecked( THEMPL->getRepeatMode() == repeat.mode );
        action->setActionGroup( repeatGroup );
        connect( action, &QAction::triggered, THEMPL, [p_intf, mode = repeat.mode]() {
            THEMPL->setRepeatMode( mode );
        });
    }

    menu->addSeparator();

    if( mi )
    {
        action = menu->addAction( qtr( "Play &Queue" ) + QStringLiteral( "\tCtrl+L" ) );
        action->setCheckable( true );
        action->setChecked( mi->getPlayqueuePanel()->isVisible() );
        connect( action, &QAction::triggered, mi->getPlayqueuePanel(), &SidePanelCtx::setVisible );
    }

    addDPStaticEntry( menu, qfut( I_PL_SAVE ), "", &DialogsProvider::savePlayingToPlaylist,
        "Ctrl+Y" );

    if( mi && mi->hasMediaLibrary() )
        addDPStaticEntry( menu, qtr( "New Playlist..." ), "", &DialogsProvider::newPlaylistDialog );
}

/**
 * Application menu of the title bar: the open entries and the dialogs of the
 * interface first, then every classic menu
 **/
void VLCMenuBar::AppMenu( qt_intf_t *p_intf, QMenu *menu )
{
    MainCtx *mi = p_intf->p_mi;
    assert( mi );
    QAction *action;

    OpenMediaEntries( p_intf, menu );
    addDPStaticEntry( menu, qtr( "Convert" ), "", &DialogsProvider::openAndTranscodingDialogs,
                      "Ctrl+R" )->setIcon( entryIcon( p_intf, menu, "swap-duo" ) );
    addRecentMenu( p_intf, menu, qtr( "Open Recent" ) );

    menu->addSeparator();

    ControlbarProfileModel *profiles = mi->controlbarProfileModel();
    if( profiles && profiles->rowCount() > 0 )
    {
        const int selected = profiles->selectedProfile();
        const QString current = profiles->data( profiles->index( selected ), Qt::DisplayRole ).toString();
        QMenu *profileMenu = new QMenu( qtr( "Profile (%1)" ).arg( current ), menu );
        QActionGroup *group = new QActionGroup( profileMenu );
        for( int i = 0; i < profiles->rowCount(); ++i )
        {
            action = profileMenu->addAction( profiles->data( profiles->index( i ), Qt::DisplayRole ).toString() );
            action->setCheckable( true );
            action->setChecked( i == selected );
            action->setActionGroup( group );
            connect( action, &QAction::triggered, profiles, [profiles, i]() {
                profiles->setSelectedProfile( i );
                profiles->save();
            });
        }
        profileMenu->addSeparator();
        addDPStaticEntry( profileMenu, qtr( "New" ), "", &DialogsProvider::showToolbarEditorDialog )
            ->setIcon( entryIcon( p_intf, profileMenu, "add", ":/menu/add.svg" ) );
        action = menu->addMenu( profileMenu );
        action->setIcon( entryIcon( p_intf, menu, "profile-duo" ) );
    }

    addDPStaticEntry( menu, qtr( "Keyboard Shortcuts" ), "", &DialogsProvider::keyboardShortcutsDialog )
        ->setIcon( entryIcon( p_intf, menu, "hotkeys-duo" ) );
    addDPStaticEntry( menu, qtr( "Customize Player" ), "", &DialogsProvider::showToolbarEditorDialog )
        ->setIcon( entryIcon( p_intf, menu, "paint-duo" ) );
    addDPStaticEntry( menu, qtr( "Global Settings..." ), "", &DialogsProvider::prefsDialog, "Ctrl+P",
                      QAction::PreferencesRole )->setIcon( entryIcon( p_intf, menu, "settings-duo" ) );
    addDPStaticEntry( menu, qtr( "About VLC" ), "", &DialogsProvider::aboutDialog, "Shift+F1",
                      QAction::AboutRole )->setIcon( entryIcon( p_intf, menu, "info-duo" ) );

    menu->addSeparator();

    FileMenu( p_intf, menu->addMenu( qtr( "&Media" ) ) );
    NavigMenu( p_intf, menu->addMenu( qtr( "P&layback" ) ) );
    AudioMenu( p_intf, menu->addMenu( qtr( "&Audio" ) ) );
    VideoMenu( p_intf, menu->addMenu( qtr( "&Video" ) ) );
    SubtitleMenu( p_intf, menu->addMenu( qtr( "Subti&tle" ) ) );
    ToolsMenu( p_intf, menu->addMenu( qtr( "Tool&s" ) ) );
    ViewMenu( p_intf, menu->addMenu( qtr( "V&iew" ) ) );
    HelpMenu( p_intf, menu->addMenu( qtr( "&Help" ) ) );
}

/* Video Tracks and Subtitles tracks */
QMenu* VLCMenuBar::VideoPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);
    VideoMenu(p_intf, menu);
    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Audio Tracks */
QMenu* VLCMenuBar::AudioPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);
    AudioMenu(p_intf, menu);
    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Navigation stuff, and general menus ( open ), used only for skins */
QMenu* VLCMenuBar::MiscPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);

    menu->addSeparator();
    PopupMenuPlaylistEntries( menu, p_intf );

    menu->addSeparator();
    PopupMenuControlEntries( menu, p_intf );

    menu->addSeparator();
    PopupMenuStaticEntries( menu );

    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Main Menu that sticks everything together  */
QMenu* VLCMenuBar::PopupMenu( qt_intf_t *p_intf, bool show )
{
    /* */
    QMenu* menu = new VLCMenu(p_intf);
    input_item_t* p_input = THEMIM->getInput();
    MainCtx *mi = p_intf->p_mi;
    QAction *action;

    PopupMenuPlaylistEntries( menu, p_intf );

    if( mi )
    {
        action = menu->addAction( ( mi->isMinimalView() ? qtr( "Show UI" ) : qtr( "Hide UI" ) )
                                  + QStringLiteral( "\tCtrl+H" ),
                                  mi, [mi]() { mi->setMinimalView( !mi->isMinimalView() ); } );
        action->setIcon( entryIcon( p_intf, menu, "ui-duo" ) );
        menu->addSeparator();
    }

    if( p_input )
    {
        QMenu *submenu;

        /* Playback menu for chapters */
        submenu = new QMenu( menu );
        NavigMenu( p_intf, submenu );
        action = menu->addMenu( submenu );
        action->setText( qtr( "&Playback" ) );
        action->setIcon( entryIcon( p_intf, menu, "playback-selected-duo" ) );
        if( action->menu()->isEmpty() )
            action->setEnabled( false );

        /* Video menu */
        submenu = new QMenu( menu );
        VideoMenu( p_intf, submenu );
        action = menu->addMenu( submenu );
        action->setText( qtr( "&Video" ) );
        action->setIcon( entryIcon( p_intf, menu, "video-duo" ) );
        if( action->menu()->isEmpty() )
            action->setEnabled( false );

        /* Audio menu */
        submenu = new QMenu( menu );
        AudioMenu( p_intf, submenu );
        action = menu->addMenu( submenu );
        action->setText( qtr( "&Audio" ) );
        action->setIcon( entryIcon( p_intf, menu, "audio-duo" ) );
        if( action->menu()->isEmpty() )
            action->setEnabled( false );

        /* Subtitles menu */
        submenu = new QMenu( menu );
        SubtitleMenu( p_intf, submenu, true );
        action = menu->addMenu( submenu );
        action->setText( qtr( "Subti&tle") );
        action->setIcon( entryIcon( p_intf, menu, "subtitles-duo" ) );

        /* Player settings panel */
        if( mi )
            addDPStaticEntry( menu, qtr( "Player &Settings" ), "",
                              []() { THEDP->playerSettingsPanel(); } )
                ->setIcon( entryIcon( p_intf, menu, "playback-settings-active" ) );
    }

    menu->addSeparator();

    if( !p_intf->b_isDialogProvider )
    {
        QMenu* settingsMenu = new QMenu( qtr( "More Settings" ), menu );
        ToolsMenu( p_intf, settingsMenu );
        settingsMenu->addSeparator();
        ViewMenu( p_intf, settingsMenu->addMenu( qtr( "V&iew" ) ) );
        HelpMenu( p_intf, settingsMenu->addMenu( qtr( "&Help" ) ) );
        action = menu->addMenu( settingsMenu );
        action->setIcon( entryIcon( p_intf, menu, "settings-duo" ) );

        QMenu* playlistMenu = new QMenu( qtr( "Play Queue" ), menu );
        PlaylistMenu( p_intf, playlistMenu );
        action = menu->addMenu( playlistMenu );
        action->setIcon( entryIcon( p_intf, menu, "playlist-duo" ) );

        QMenu* openMenu = new QMenu( qtr( "Open Media" ), menu );
        OpenMediaEntries( p_intf, openMenu );
        addRecentMenu( p_intf, openMenu, qtr( "Open Recent" ) );
        action = menu->addMenu( openMenu );
        action->setIcon( entryIcon( p_intf, menu, "file-duo" ) );

        addDPStaticEntry( menu, qtr( "Quit" ), "", &DialogsProvider::quit, "Ctrl+Q",
                          QAction::QuitRole )->setIcon( entryIcon( p_intf, menu, "quit-duo" ) );

        if( show )
            menu->popup( QCursor::pos() );
        return menu;
    }

    /* skins: same as Tool menu but with extra entries */
    {
        QMenu* submenu = new QMenu( qtr( "Interface" ), menu );
        ToolsMenu( p_intf, submenu );
        submenu->addSeparator();

        vlc_object_t* p_object = vlc_object_parent(p_intf->intf);

        /* Open skin dialog box */
        if (var_Type(p_object, "intf-skins-interactive") & VLC_VAR_ISCOMMAND)
        {
            QAction* openSkinAction = new QAction(qtr("Open skin..."), menu);
            openSkinAction->setShortcut( QKeySequence( "Ctrl+Shift+S" ));
            connect(openSkinAction, &QAction::triggered, [=]() {
                var_TriggerCallback(p_object, "intf-skins-interactive");
            });
            submenu->addAction(openSkinAction);
        }

        VLCVarChoiceModel* skinmodel = new VLCVarChoiceModel(p_object, "intf-skins", submenu);
        CheckableListMenu* skinsubmenu = new CheckableListMenu(qtr("Interface"), skinmodel, QActionGroup::ExclusionPolicy::ExclusiveOptional, submenu);
        submenu->addMenu(skinsubmenu);

        submenu->addSeparator();

        /* list of extensions */
        ExtensionsMenu( p_intf, submenu );

        menu->addMenu( submenu );
    }

    /* Static entries for ending, like open */
    QMenu* openmenu = new QMenu( qtr( "Open Media" ), menu );
    FileMenu( p_intf, openmenu );
    menu->addMenu( openmenu );

    menu->addSeparator();

    QMenu* helpmenu = new QMenu( qtr( "Help" ), menu );
    HelpMenu( p_intf, helpmenu );
    menu->addMenu( helpmenu );

    addDPStaticEntry( menu, qtr( "Quit" ), ":/menu/exit.svg",
                      &DialogsProvider::quit, "Ctrl+Q", QAction::QuitRole );

    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}
