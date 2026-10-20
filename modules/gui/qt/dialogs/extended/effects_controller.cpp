/*****************************************************************************
 * effects_controller.cpp : audio and video effects for the player panel
 ****************************************************************************
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

#include <algorithm>

#include <QLocale>
#include <QSettings>

#include "effects_controller.hpp"
#include "dialogs/settings/settings_bridge.hpp"
#include "player/player_controller.hpp"
#include "util/renderer_manager.hpp"

#include "../../../../audio_filter/equalizer_presets.h"
#include <vlc_actions.h>
#include <vlc_configuration.h>
#include <vlc_modules.h>
#include <vlc_player.h>
#include <vlc_aout.h>
#include <vlc_vout.h>

#define PRESETS_KEY "PlayerSettings/Presets"
#define SUBSDELAY_CFG_FACTOR "subsdelay-factor"

bool filterIsPresent( const QString &filters, const QString &filter )
{
    const QStringList list = filters.split( ':', Qt::SkipEmptyParts );
    return list.contains( filter );
}

const char* GetVFilterType( qt_intf_t *p_intf, const char *psz_name )
{
    module_t *p_obj = module_find( psz_name );
    if( !p_obj )
    {
        msg_Err( p_intf, "Unable to find filter module \"%s\".", psz_name );
        return NULL;
    }

    if( module_provides( p_obj, "video splitter" ) )
        return "video-splitter";
    else if( module_provides( p_obj, "video filter" ) )
        return "video-filter";
    else if( module_provides( p_obj, "sub source" ) )
        return "sub-source";
    else if( module_provides( p_obj, "sub filter" ) )
        return "sub-filter";
    else
    {
        msg_Err( p_intf, "Unknown video filter type." );
        return NULL;
    }
}

static QString ChangeFilterList( const QString &chain, const QString &name, bool b_add )
{
    QStringList list = chain.split( ':', Qt::SkipEmptyParts );

    if( b_add && !list.contains( name ) )
        list << name;
    else if( !b_add )
        list.removeAll( name );

    return list.join( ":" );
}

QString ChangeFiltersString( qt_intf_t *p_intf, const char *psz_filter_type, const char *psz_name, bool b_add )
{
    char *psz_chain = nullptr;
    if (const auto vout = THEMIM->getVout(); vout != nullptr)
        psz_chain = var_GetString( vout.get(), psz_filter_type );

    QString const chain = ChangeFilterList( qfu( psz_chain ), qfu( psz_name ), b_add );
    free( psz_chain );
    return chain;
}

void UpdateVFiltersString( qt_intf_t *p_intf,
                           const char *psz_filter_type, const char *value )
{
    /* Try to set non splitter filters on the fly */
    if( strcmp( psz_filter_type, "video-splitter" ) )
    {
        auto p_vout = THEMIM->getVout();
        if( p_vout )
            var_SetString( p_vout.get(), psz_filter_type, value );
    }
}

static QVariant VarToVariant( vlc_object_t *p_obj, const char *psz_name, int i_type )
{
    switch( i_type & VLC_VAR_CLASS )
    {
        case VLC_VAR_BOOL:
            return QVariant( var_GetBool( p_obj, psz_name ) );
        case VLC_VAR_INTEGER:
            return QVariant( qlonglong( var_GetInteger( p_obj, psz_name ) ) );
        case VLC_VAR_FLOAT:
            return QVariant( double( var_GetFloat( p_obj, psz_name ) ) );
        case VLC_VAR_STRING:
        {
            char *psz = var_GetString( p_obj, psz_name );
            QString value = qfu( psz );
            free( psz );
            return QVariant( value );
        }
        default:
            return {};
    }
}

static int VariantToValue( const QVariant &value, int i_type, vlc_value_t *val, QByteArray &storage )
{
    switch( i_type & VLC_VAR_CLASS )
    {
        case VLC_VAR_BOOL:
            val->b_bool = value.toBool();
            return VLC_SUCCESS;
        case VLC_VAR_INTEGER:
            val->i_int = value.toLongLong();
            return VLC_SUCCESS;
        case VLC_VAR_FLOAT:
            val->f_float = value.toFloat();
            return VLC_SUCCESS;
        case VLC_VAR_STRING:
            storage = value.toString().toUtf8();
            val->psz_string = storage.data();
            return VLC_SUCCESS;
        default:
            return VLC_EGENERIC;
    }
}

/* The text scale is a variable of the player, which has no event for it, so
 * the hotkeys that change it are followed instead */
static int KeyActionCallback( vlc_object_t *, const char *, vlc_value_t,
                              vlc_value_t newval, void *data )
{
    switch( newval.i_int )
    {
        case ACTIONID_SUBTITLE_TEXT_SCALE_NORMAL:
        case ACTIONID_SUBTITLE_TEXT_SCALE_UP:
        case ACTIONID_SUBTITLE_TEXT_SCALE_DOWN:
            QMetaObject::invokeMethod( static_cast<EffectsController *>( data ),
                                       &EffectsController::subtitleTextScaleChanged,
                                       Qt::QueuedConnection );
            break;
        default:
            break;
    }
    return VLC_SUCCESS;
}

EffectsController::EffectsController( qt_intf_t *_p_intf, QObject *parent )
    : QObject( parent )
    , p_intf( _p_intf )
{
    var_AddCallback( vlc_object_instance( p_intf ), "key-action", KeyActionCallback, this );

    m_sleepTimer.setSingleShot( true );
    connect( &m_sleepTimer, &QTimer::timeout, this, [this]() {
        {
            vlc_player_locker lock{ p_intf->p_player };
            vlc_player_Pause( p_intf->p_player );
        }
        m_sleepMinutes = 0;
        emit sleepTimerChanged();
    } );

    connect( THEMIM, &PlayerController::voutListChanged, this, &EffectsController::bump );
    connect( THEMIM, &PlayerController::inputChanged, this, &EffectsController::bump );
}

EffectsController::~EffectsController()
{
    var_DelCallback( vlc_object_instance( p_intf ), "key-action", KeyActionCallback, this );
}

bool EffectsController::isFilterEnabled( const QString &module ) const
{
    module_t *p_obj = module_find( qtu( module ) );
    if( !p_obj )
        return false;

    char *psz_chain = nullptr;
    if( module_provides( p_obj, "audio filter" ) )
    {
        if( SharedAOut p_aout = THEMIM->getAout() )
            psz_chain = var_GetString( p_aout.get(), "audio-filter" );
        else
            psz_chain = config_GetPsz( "audio-filter" );
    }
    else
    {
        const char *psz_filter_type = GetVFilterType( p_intf, qtu( module ) );
        if( psz_filter_type == NULL )
            return false;

        if( SharedVOutThread p_vout = THEMIM->getVout() )
            psz_chain = var_GetString( p_vout.get(), psz_filter_type );
        else
            psz_chain = config_GetPsz( psz_filter_type );
    }

    const bool b_present = filterIsPresent( qfu( psz_chain ), module );
    free( psz_chain );
    return b_present;
}

void EffectsController::setFilterEnabled( const QString &module, bool enable )
{
    if( isFilterEnabled( module ) == enable )
        return;

    module_t *p_obj = module_find( qtu( module ) );
    if( !p_obj )
    {
        msg_Err( p_intf, "Unable to find filter module \"%s\".", qtu( module ) );
        return;
    }

    if( module_provides( p_obj, "audio filter" ) )
    {
        char *psz_chain = config_GetPsz( "audio-filter" );
        const QString chain = ChangeFilterList( qfu( psz_chain ), module, enable );
        free( psz_chain );

        config_PutPsz( "audio-filter", qtu( chain ) );
        vlc_player_aout_EnableFilter( p_intf->p_player, qtu( module ), enable );
    }
    else
    {
        const char *psz_filter_type = GetVFilterType( p_intf, qtu( module ) );
        if( psz_filter_type == NULL )
            return;

        char *psz_chain = config_GetPsz( psz_filter_type );
        const QString chain = ChangeFilterList( qfu( psz_chain ), module, enable );
        free( psz_chain );
        config_PutPsz( psz_filter_type, qtu( chain ) );

        const QString voutChain = ChangeFiltersString( p_intf, psz_filter_type, qtu( module ), enable );
        UpdateVFiltersString( p_intf, psz_filter_type, qtu( voutChain ) );
    }

    bump();
}

QVariant EffectsController::option( const QString &name ) const
{
    const QByteArray psz_name = name.toUtf8();

    if( SharedAOut p_aout = THEMIM->getAout() )
    {
        const int i_type = var_Type( p_aout.get(), psz_name.constData() );
        if( i_type != 0 )
            return VarToVariant( VLC_OBJECT( p_aout.get() ), psz_name.constData(), i_type );
    }

    if( SharedVOutThread p_vout = THEMIM->getVout() )
    {
        const int i_type = var_Type( p_vout.get(), psz_name.constData() );
        if( i_type != 0 )
            return VarToVariant( VLC_OBJECT( p_vout.get() ), psz_name.constData(), i_type );
    }

    return ConfigOption( name ).value();
}

QVariant EffectsController::defaultOption( const QString &name ) const
{
    return ConfigOption( name ).defaultValue();
}

void EffectsController::setOption( const QString &name, const QVariant &value )
{
    const QByteArray psz_name = name.toUtf8();
    const char *psz = psz_name.constData();

    SharedAOut p_aout = THEMIM->getAout();
    const PlayerController::VOutThreadList vouts = THEMIM->getVouts();

    int i_type = config_GetType( psz );
    if( i_type == 0 && p_aout )
        i_type = var_Type( p_aout.get(), psz );
    for( auto it = vouts.cbegin(); i_type == 0 && it != vouts.cend(); ++it )
        i_type = var_Type( it->get(), psz );

    vlc_value_t val;
    QByteArray storage;
    if( VariantToValue( value, i_type, &val, storage ) != VLC_SUCCESS )
    {
        msg_Err( p_intf, "Option %s is of an unsupported type ( %d )", psz, i_type );
        return;
    }
    i_type &= VLC_VAR_CLASS;

    if( p_aout && var_Type( p_aout.get(), psz ) != 0 )
        var_SetChecked( p_aout.get(), psz, i_type, val );

    for( const auto &p_vout : vouts )
        if( var_Type( p_vout.get(), psz ) != 0 )
            var_SetChecked( p_vout.get(), psz, i_type, val );

    ConfigOption( name ).setValue( value );
    bump();
}

QVariantList EffectsController::optionChoices( const QString &name ) const
{
    return ConfigOption( name ).choices();
}

QStringList EffectsController::bandsFromOutput() const
{
    QStringList bands = option( "equalizer-bands" ).toString().split( ' ', Qt::SkipEmptyParts );
    if( bands.count() >= EQZ_BANDS_MAX )
        return bands;

    const QVariantList preset = SettingsBridge::equalizerPreset( option( "equalizer-preset" ).toString() )
                                    .value( "bands" ).toList();
    bands.clear();
    for( int i = 0; i < EQZ_BANDS_MAX; i++ )
        bands << QLocale( QLocale::C ).toString( preset.value( i, 0.f ).toFloat() );
    return bands;
}

QVariantList EffectsController::equalizerBands() const
{
    QVariantList values;
    for( const QString &band : bandsFromOutput() )
        values << QVariant( double( QLocale( QLocale::C ).toFloat( band ) ) );
    return values;
}

void EffectsController::setEqualizerBand( int index, double value )
{
    QStringList bands = bandsFromOutput();
    if( index < 0 || index >= bands.count() )
        return;

    bands[index] = QLocale( QLocale::C ).toString( float( value ) );
    setOption( "equalizer-bands", bands.join( " " ) );
    setFilterEnabled( "equalizer", true );
}

QString EffectsController::equalizerPreset() const
{
    if( !isFilterEnabled( "equalizer" ) )
        return {};
    return option( "equalizer-preset" ).toString();
}

void EffectsController::setEqualizerPreset( const QString &preset )
{
    if( preset.isEmpty() )
    {
        setFilterEnabled( "equalizer", false );
        return;
    }

    const QVariantMap values = SettingsBridge::equalizerPreset( preset );
    if( values.isEmpty() )
        return;

    QStringList bands;
    for( const QVariant &band : values.value( "bands" ).toList() )
        bands << QLocale( QLocale::C ).toString( band.toFloat() );

    setOption( "equalizer-preset", preset );
    setOption( "equalizer-preamp", values.value( "preamp" ) );
    setOption( "equalizer-bands", bands.join( " " ) );
    setFilterEnabled( "equalizer", true );
    bump();
}

QVariantList EffectsController::crop() const
{
    SharedVOutThread p_vout = THEMIM->getVout();
    if( !p_vout )
        return { 0, 0, 0, 0 };

    return { int( var_GetInteger( p_vout.get(), "crop-top" ) ),
             int( var_GetInteger( p_vout.get(), "crop-bottom" ) ),
             int( var_GetInteger( p_vout.get(), "crop-left" ) ),
             int( var_GetInteger( p_vout.get(), "crop-right" ) ) };
}

void EffectsController::setCrop( int top, int bottom, int left, int right )
{
    for( const auto &p_vout : THEMIM->getVouts() )
    {
        var_SetInteger( p_vout.get(), "crop-top", top );
        var_SetInteger( p_vout.get(), "crop-bottom", bottom );
        var_SetInteger( p_vout.get(), "crop-left", left );
        var_SetInteger( p_vout.get(), "crop-right", right );
    }
    bump();
}

double EffectsController::subtitleDurationFactor() const
{
    SharedVOutThread p_vout = THEMIM->getVout();
    if( !p_vout || !isFilterEnabled( "subsdelay" )
     || var_Type( p_vout.get(), SUBSDELAY_CFG_FACTOR ) == 0 )
        return 0.;
    return var_GetFloat( p_vout.get(), SUBSDELAY_CFG_FACTOR );
}

void EffectsController::setSubtitleDurationFactor( double factor )
{
    /* Like the synchronization panel, this only lasts for the current media */
    for( const auto &p_vout : THEMIM->getVouts() )
    {
        if( var_Type( p_vout.get(), SUBSDELAY_CFG_FACTOR ) == 0 )
            var_Create( p_vout.get(), SUBSDELAY_CFG_FACTOR, VLC_VAR_FLOAT );
        var_SetFloat( p_vout.get(), SUBSDELAY_CFG_FACTOR, factor );
    }

    const char *psz_filter_type = GetVFilterType( p_intf, "subsdelay" );
    if( psz_filter_type == NULL )
        return;
    const QString chain = ChangeFiltersString( p_intf, psz_filter_type, "subsdelay", factor > 0 );
    UpdateVFiltersString( p_intf, psz_filter_type, qtu( chain ) );
    bump();
}

void EffectsController::selectRenderer( int row )
{
    RendererManager *manager = THEMIM->getRendererManager();
    if( row < 0 )
        manager->disableRenderer();
    else
        manager->setData( manager->index( row ), true, RendererManager::SELECTED );
    bump();
}

int EffectsController::getRevision() const
{
    return m_revision;
}

void EffectsController::bump()
{
    m_revision++;
    emit changed();
}

int EffectsController::getSubtitleTextScale() const
{
    vlc_player_locker lock{ p_intf->p_player };
    return vlc_player_GetSubtitleTextScale( p_intf->p_player );
}

void EffectsController::setSubtitleTextScale( int scale )
{
    if( scale == getSubtitleTextScale() )
        return;

    {
        vlc_player_locker lock{ p_intf->p_player };
        vlc_player_SetSubtitleTextScale( p_intf->p_player, scale );
    }
    config_PutInt( "sub-text-scale", scale );
    emit subtitleTextScaleChanged();
}

int EffectsController::getSleepTimer() const
{
    return m_sleepMinutes;
}

void EffectsController::setSleepTimer( int minutes )
{
    if( minutes == m_sleepMinutes )
        return;

    m_sleepMinutes = minutes;
    if( minutes > 0 )
        m_sleepTimer.start( minutes * 60 * 1000 );
    else
        m_sleepTimer.stop();
    emit sleepTimerChanged();
}

QVariantList EffectsController::getPresets() const
{
    return getSettings()->value( PRESETS_KEY ).toList();
}

void EffectsController::savePreset( const QString &name, const QVariantMap &values )
{
    QVariantList presets = getPresets();
    const QVariantMap preset{ { "name", name }, { "values", values } };

    auto it = std::find_if( presets.begin(), presets.end(), [&name]( const QVariant &p ) {
        return p.toMap().value( "name" ).toString() == name;
    } );
    if( it != presets.end() )
        *it = preset;
    else
        presets.append( preset );

    getSettings()->setValue( PRESETS_KEY, presets );
    emit presetsChanged();
}

void EffectsController::removePreset( const QString &name )
{
    QVariantList presets = getPresets();
    presets.erase( std::remove_if( presets.begin(), presets.end(), [&name]( const QVariant &p ) {
        return p.toMap().value( "name" ).toString() == name;
    } ), presets.end() );

    getSettings()->setValue( PRESETS_KEY, presets );
    emit presetsChanged();
}
