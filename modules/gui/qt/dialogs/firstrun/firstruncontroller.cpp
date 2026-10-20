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

#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"

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
        m_folder = displayPath( qfu( videos.get() ) );
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

    QStringList keys;
    if( code & KEY_MODIFIER_CTRL )
        keys << qtr( "Ctrl" ).toUpper();
    if( code & KEY_MODIFIER_ALT )
        keys << qtr( "Alt" ).toUpper();
    if( code & KEY_MODIFIER_SHIFT )
        keys << qtr( "Shift" ).toUpper();
    if( code & KEY_MODIFIER_META )
        keys << qtr( "Meta" ).toUpper();
    if( code & KEY_MODIFIER_COMMAND )
        keys << qtr( "Command" ).toUpper();

    const uint_fast32_t key = code & ~KEY_MODIFIER;
    switch( key )
    {
        case KEY_LEFT:  keys << QStringLiteral( "←" ); break;
        case KEY_RIGHT: keys << QStringLiteral( "→" ); break;
        case KEY_UP:    keys << QStringLiteral( "↑" ); break;
        case KEY_DOWN:  keys << QStringLiteral( "↓" ); break;
        default:
        {
            auto keyName = vlc::wrap_cptr( vlc_keycode2str( key, true ) );
            if( !keyName )
                return {};
            const QString text = qfu( keyName.get() );
            keys << ( text.size() == 1 ? text.toUpper() : text );
        }
    }
    return keys;
}

void FirstRunController::finish()
{
    addFolder();
    apply();
}

void FirstRunController::skip()
{
    apply();
}

void FirstRunController::addFolder()
{
    MediaLib* mediaLib = m_ctx->getMediaLibrary();
    if( !mediaLib )
        return;

    const QString path = expandPath( m_folder );
    if( path.isEmpty() || !QFileInfo( path ).isDir() )
        return;

    auto mrl = vlc::wrap_cptr( vlc_path2uri( qtu( QDir::toNativeSeparators( path ) ), nullptr ) );
    if( !mrl )
        return;

    mediaLib->runOnMLThread( mediaLib,
    [entryPoint = std::string( mrl.get() )]( vlc_medialibrary_t* ml ) {
        vlc_ml_add_folder( ml, entryPoint.c_str() );
    },
    ML_FOLDER_ADD_QUEUE );
}

void FirstRunController::apply()
{
    assert( m_ctx );
    qt_intf_t* p_intf = m_ctx->getIntf();

    config_PutInt( "metadata-network-access", m_metadataNetworkAccess );
    config_PutInt( "qt-privacy-ask", 0 );

    /* Modern layout: client-side decoration and no menu bar */
    config_PutInt( "qt-menubar", 0 );
    config_PutInt( "qt-titlebar", 0 );

    if( m_ctx->getMediaLibrary() )
        m_ctx->getMediaLibrary()->reload();

    m_ctx->reloadPrefs();
    config_SaveConfigFile( p_intf );
}
