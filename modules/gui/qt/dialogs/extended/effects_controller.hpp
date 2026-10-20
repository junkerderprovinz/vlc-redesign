/*****************************************************************************
 * effects_controller.hpp : audio and video effects for the player panel
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

#ifndef VLC_QT_EFFECTS_CONTROLLER_HPP_
#define VLC_QT_EFFECTS_CONTROLLER_HPP_

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariant>

#include "qt.hpp"

/* Filter chain helpers shared with the extended dialog */
bool filterIsPresent( const QString &filters, const QString &filter );
const char *GetVFilterType( qt_intf_t *p_intf, const char *psz_name );
QString ChangeFiltersString( qt_intf_t *p_intf, const char *psz_filter_type,
                             const char *psz_name, bool b_add );
void UpdateVFiltersString( qt_intf_t *p_intf, const char *psz_filter_type,
                           const char *value );

/**
 * Reads and changes the audio and video filters of the playing media, the
 * same way the extended dialog does: options go to the running audio and
 * video outputs and to the configuration, so the next media keeps them.
 */
class EffectsController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList equalizerBandNames READ getEqualizerBandNames CONSTANT FINAL)
    Q_PROPERTY(QVariantList equalizerPresets READ getEqualizerPresets CONSTANT FINAL)
    Q_PROPERTY(int subtitleTextScale READ getSubtitleTextScale WRITE setSubtitleTextScale NOTIFY subtitleTextScaleChanged FINAL)
    Q_PROPERTY(int sleepTimer READ getSleepTimer WRITE setSleepTimer NOTIFY sleepTimerChanged FINAL)
    Q_PROPERTY(QVariantList presets READ getPresets NOTIFY presetsChanged FINAL)
    /* grows on every change, bindings that read options depend on it */
    Q_PROPERTY(int revision READ getRevision NOTIFY changed FINAL)

public:
    explicit EffectsController( qt_intf_t *p_intf, QObject *parent = nullptr );

    Q_INVOKABLE bool isFilterEnabled( const QString &module ) const;
    Q_INVOKABLE void setFilterEnabled( const QString &module, bool enable );

    Q_INVOKABLE QVariant option( const QString &name ) const;
    Q_INVOKABLE QVariant defaultOption( const QString &name ) const;
    Q_INVOKABLE void setOption( const QString &name, const QVariant &value );
    Q_INVOKABLE QVariantList optionChoices( const QString &name ) const;

    Q_INVOKABLE QVariantList equalizerBands() const;
    Q_INVOKABLE void setEqualizerBand( int index, double value );
    Q_INVOKABLE QString equalizerPreset() const;
    Q_INVOKABLE void setEqualizerPreset( const QString &preset );

    Q_INVOKABLE QVariantList crop() const;
    Q_INVOKABLE void setCrop( int top, int bottom, int left, int right );

    Q_INVOKABLE double subtitleDurationFactor() const;
    Q_INVOKABLE void setSubtitleDurationFactor( double factor );

    Q_INVOKABLE void selectRenderer( int row );

    Q_INVOKABLE void savePreset( const QString &name, const QVariantMap &values );
    Q_INVOKABLE void removePreset( const QString &name );

    QStringList getEqualizerBandNames() const;
    QVariantList getEqualizerPresets() const;
    int getSubtitleTextScale() const;
    void setSubtitleTextScale( int scale );
    int getSleepTimer() const;
    void setSleepTimer( int minutes );
    QVariantList getPresets() const;
    int getRevision() const;

signals:
    /* the outputs or their filters changed, values should be read again */
    void changed();
    void subtitleTextScaleChanged();
    void sleepTimerChanged();
    void presetsChanged();

private:
    QStringList bandsFromOutput() const;
    void bump();

    qt_intf_t *p_intf;
    int m_revision = 0;
    QTimer m_sleepTimer;
    int m_sleepMinutes = 0;
};

#endif
