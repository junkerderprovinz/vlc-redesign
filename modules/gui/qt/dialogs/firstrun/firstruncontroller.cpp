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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "firstruncontroller.hpp"

#include "dialogs/toolbar/controlbar_profile_model.hpp"
#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"
#include "util/vlchotkeyconverter.hpp"

#include <QDir>
#include <QFileDialog>
#include <QFileInfo>
#include <QUrl>

#include <vlc_common.h>
#include <vlc_actions.h>
#include <vlc_configuration.h>
#include <vlc_media_library.h>
#include <vlc_url.h>
#include <vlc_cxx_helpers.hpp>

#include <cassert>
#include <string>

namespace {

const char* const ML_FOLDER_ADD_QUEUE = "ML_FOLDER_ADD_QUEUE";

QString displayPath( const QString& path )
{
    const QString native = QDir::toNativeSeparators( path );
#ifndef _WIN32
    const QString home = QDir::homePath();
    if( native == home || native.startsWith( home + QLatin1Char( '/' ) ) )
        return QLatin1Char( '~' ) + native.mid( home.length() );
#endif
    return native;
}

QString expandPath( const QString& text )
{
    QString path = text.trimmed();
    if( path == QLatin1String( "~" ) || path.startsWith( QLatin1String( "~/" ) ) )
        path = QDir::homePath() + path.mid( 1 );
    return QDir::fromNativeSeparators( path );
}

}

FirstRunController::FirstRunController( QObject *parent )
    : QObject( parent )
{
    auto videos = vlc::wrap_cptr( config_GetUserDir( VLC_VIDEOS_DIR ) );
    if( videos )
        m_folder = m_defaultFolder = displayPath( qfu( videos.get() ) );
}

void FirstRunController::setCtx( MainCtx* ctx )
{
    if( m_ctx == ctx )
        return;
    m_ctx = ctx;
    emit ctxChanged();
}

void FirstRunController::setFolder( const QString& folder )
{
    if( m_folder == folder )
        return;
    m_folder = folder;
    emit folderChanged();
}

void FirstRunController::browseFolder()
{
    QString start = expandPath( m_folder );
    if( start.isEmpty() || !QFileInfo( start ).isDir() )
        start = QDir::homePath();

    const QUrl url = QFileDialog::getExistingDirectoryUrl( nullptr,
        qtr( "Choose a folder to add to the Media Library" ),
        QUrl::fromLocalFile( start ), QFileDialog::ShowDirsOnly,
        QStringList( QStringLiteral( "file" ) ) );

    if( !url.isEmpty() )
        setFolder( displayPath( url.toLocalFile() ) );
}

void FirstRunController::setColorScheme( ColorSchemeModel::ColorScheme scheme )
{
    assert( m_ctx );
    ColorSchemeModel* model = m_ctx->getColorScheme();
    const QVector<ColorSchemeModel::Item> schemes = model->getSchemes();
    for( int i = 0; i < schemes.size(); ++i )
    {
        if( schemes.at( i ).scheme == scheme )
        {
            model->setCurrentIndex( i );
            return;
        }
    }
}

QStringList FirstRunController::hotkey( const QString& name ) const
{
    auto value = vlc::wrap_cptr( config_GetPsz( qtu( name ) ) );
    if( !value )
        return {};

    /* Only the first of the alternative bindings is shown */
    const QString first = qfu( value.get() ).section( QLatin1Char( '\t' ), 0, 0 );
    const uint_fast32_t code = vlc_str2keycode( qtu( first ) );
    if( code == KEY_UNSET )
        return {};

    QStringList keys = VLCKeyToStringList( code );
    if( keys.isEmpty() )
        return {};

    /* the key caps print modifiers in capitals and arrows as symbols */
    for( qsizetype i = 0; i < keys.size() - 1; ++i )
        keys[i] = keys[i].toUpper();
    switch( code & ~KEY_MODIFIER )
    {
        case KEY_LEFT:  keys.back() = QStringLiteral( "←" ); break;
        case KEY_RIGHT: keys.back() = QStringLiteral( "→" ); break;
        case KEY_UP:    keys.back() = QStringLiteral( "↑" ); break;
        case KEY_DOWN:  keys.back() = QStringLiteral( "↓" ); break;
    }
    return keys;
}

void FirstRunController::finish()
{
    addFolders();
    apply();
}

void FirstRunController::skip()
{
    apply();
}

void FirstRunController::addFolders()
{
    assert( m_ctx );
    MediaLib* mediaLib = m_ctx->getMediaLibrary();
    if( !mediaLib )
        return;

    QStringList paths { expandPath( m_folder ) };
    /* unless another folder was chosen, the music goes with the videos */
    if( m_folder == m_defaultFolder )
    {
        auto music = vlc::wrap_cptr( config_GetUserDir( VLC_MUSIC_DIR ) );
        if( music && !paths.contains( qfu( music.get() ) ) )
            paths << qfu( music.get() );
    }

    for( const QString& path : paths )
    {
        if( path.isEmpty() || !QFileInfo( path ).isDir() )
            continue;

        auto mrl = vlc::wrap_cptr( vlc_path2uri( qtu( QDir::toNativeSeparators( path ) ), nullptr ) );
        if( !mrl )
            continue;

        mediaLib->runOnMLThread( mediaLib,
        [entryPoint = std::string( mrl.get() )]( vlc_medialibrary_t* ml ) {
            vlc_ml_add_folder( ml, entryPoint.c_str() );
        },
        ML_FOLDER_ADD_QUEUE );
    }
}

void FirstRunController::apply()
{
    assert( m_ctx );
    qt_intf_t* p_intf = m_ctx->getIntf();

    config_PutInt( "metadata-network-access", m_metadataNetworkAccess );
    config_PutInt( "qt-privacy-ask", 0 );

    /* the modern layout draws its own title bar and has no menu bar, the
     * classic one keeps both and pins the controls under the video */
    config_PutInt( "qt-menubar", m_classicLayout );
    config_PutInt( "qt-titlebar", m_classicLayout );
    if( m_classicLayout )
    {
        config_PutInt( "qt-pin-controls", 1 );

        ControlbarProfileModel* controlbarModel = m_ctx->controlbarProfileModel();
        std::unique_ptr<ControlbarProfile> profile(
            ControlbarProfileModel::generateProfileFromStyle( ControlbarProfileModel::Style::CLASSIC_STYLE ) );
        if( const std::optional<int> index = controlbarModel->findModel( profile.get() ) )
            controlbarModel->setSelectedProfile( *index );
        else
            controlbarModel->insertProfile( std::move( profile ), true );
        controlbarModel->save();
    }

    if( m_ctx->getMediaLibrary() )
        m_ctx->getMediaLibrary()->reload();

    m_ctx->reloadPrefs();
    config_SaveConfigFile( p_intf );
}
