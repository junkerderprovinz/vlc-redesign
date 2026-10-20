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

#include "settings_bridge.hpp"

#include "dialogs/dialogs/dialogmodel.hpp"
#include "dialogs/dialogs_provider.hpp"
#include "maininterface/mainctx.hpp"

#include <vlc_configuration.h>
#include <vlc_modules.h>
#include <vlc_plugin.h>
#include <vlc_aout.h>

#include <QDesktopServices>
#include <QFileDialog>
#include <QRegularExpression>
#include <QSettings>
#include <QUrl>

#include <cfloat>
#include <cmath>

#include "../../../../audio_filter/equalizer_presets.h"

namespace {

SettingsBridge *s_bridge = nullptr;

QStringList splitModules(const QString &list)
{
    static const QRegularExpression separator(QStringLiteral("[:,]"));
    return list.split(separator, Qt::SkipEmptyParts);
}

QString moduleName(const QString &entry)
{
    return entry.section(QLatin1Char('{'), 0, 0).trimmed();
}

QString configString(const char *name)
{
    char *psz = config_GetPsz(name);
    QString ret = qfu(psz);
    free(psz);
    return ret;
}

}

ConfigOption::ConfigOption(QObject *parent)
    : QObject(parent)
{
    if (s_bridge)
        connect(s_bridge, &SettingsBridge::optionChanged, this, &ConfigOption::onOptionChanged);
}

void ConfigOption::setName(const QString &name)
{
    if (name == m_name)
        return;
    m_name = name;
    m_key = name.toUtf8();
    m_config = name.isEmpty() ? nullptr : config_FindConfig(m_key.constData());
    emit nameChanged();
    emit valueChanged();
}

ConfigOption::Type ConfigOption::type() const
{
    if (!m_config)
        return TYPE_NONE;

    switch (m_config->i_type)
    {
    case CONFIG_ITEM_BOOL:
        return TYPE_BOOL;
    case CONFIG_ITEM_RGB:
        return TYPE_COLOR;
    case CONFIG_ITEM_INTEGER:
        return TYPE_INTEGER;
    case CONFIG_ITEM_FLOAT:
        return TYPE_FLOAT;
    case CONFIG_ITEM_PASSWORD:
        return TYPE_PASSWORD;
    case CONFIG_ITEM_LOADFILE:
    case CONFIG_ITEM_SAVEFILE:
        return TYPE_FILE;
    case CONFIG_ITEM_DIRECTORY:
        return TYPE_DIRECTORY;
    case CONFIG_ITEM_FONT:
        return TYPE_FONT;
    case CONFIG_ITEM_MODULE:
    case CONFIG_ITEM_MODULE_CAT:
        return TYPE_MODULE;
    default:
        return TYPE_STRING;
    }
}

QString ConfigOption::text() const
{
    if (!m_config || !m_config->psz_text)
        return {};
    return qfut(m_config->psz_text);
}

QString ConfigOption::longText() const
{
    if (!m_config || !m_config->psz_longtext)
        return {};
    return qfut(m_config->psz_longtext);
}

QVariant ConfigOption::value() const
{
    if (!m_config)
        return {};

    const char *key = m_key.constData();
    if (m_config->i_type == CONFIG_ITEM_BOOL)
        return config_GetInt(key) != 0;
    if (IsConfigIntegerType(m_config->i_type))
        return QVariant::fromValue<qlonglong>(config_GetInt(key));
    if (IsConfigFloatType(m_config->i_type))
        return static_cast<double>(config_GetFloat(key));
    return configString(key);
}

void ConfigOption::setValue(const QVariant &value)
{
    if (!m_config || value == this->value())
        return;

    const char *key = m_key.constData();
    if (m_config->i_type == CONFIG_ITEM_BOOL)
        config_PutInt(key, value.toBool());
    else if (IsConfigIntegerType(m_config->i_type))
        config_PutInt(key, value.toLongLong());
    else if (IsConfigFloatType(m_config->i_type))
        config_PutFloat(key, value.toFloat());
    else
        config_PutPsz(key, qtu(value.toString()));

    if (s_bridge)
        s_bridge->notify(m_name);
    else
        emit valueChanged();
}

QVariant ConfigOption::defaultValue() const
{
    if (!m_config)
        return {};

    if (m_config->i_type == CONFIG_ITEM_BOOL)
        return m_config->orig.i != 0;
    if (IsConfigIntegerType(m_config->i_type))
        return QVariant::fromValue<qlonglong>(m_config->orig.i);
    if (IsConfigFloatType(m_config->i_type))
        return static_cast<double>(m_config->orig.f);
    return qfu(m_config->orig.psz);
}

QVariant ConfigOption::minimum() const
{
    if (!m_config)
        return {};
    if (IsConfigIntegerType(m_config->i_type) && m_config->min.i != INT64_MIN)
        return QVariant::fromValue<qlonglong>(m_config->min.i);
    if (IsConfigFloatType(m_config->i_type) && m_config->min.f > -FLT_MAX)
        return static_cast<double>(m_config->min.f);
    return {};
}

QVariant ConfigOption::maximum() const
{
    if (!m_config)
        return {};
    if (IsConfigIntegerType(m_config->i_type) && m_config->max.i != INT64_MAX)
        return QVariant::fromValue<qlonglong>(m_config->max.i);
    if (IsConfigFloatType(m_config->i_type) && m_config->max.f < FLT_MAX)
        return static_cast<double>(m_config->max.f);
    return {};
}

QVariantList ConfigOption::choices() const
{
    QVariantList ret;
    if (!m_config || m_config->i_type == CONFIG_ITEM_BOOL)
        return ret;

    const char *key = m_key.constData();
    if (IsConfigIntegerType(m_config->i_type))
    {
        int64_t *values;
        char **texts;
        const ssize_t count = config_GetIntChoices(key, &values, &texts);
        for (ssize_t i = 0; i < count; i++)
        {
            ret.append(QVariantMap {
                { QStringLiteral("value"), QVariant::fromValue<qlonglong>(values[i]) },
                { QStringLiteral("text"), qfu(texts[i]) },
            });
            free(texts[i]);
        }
        if (count >= 0)
        {
            free(values);
            free(texts);
        }
    }
    else if (IsConfigStringType(m_config->i_type))
    {
        char **values, **texts;
        const ssize_t count = config_GetPszChoices(key, &values, &texts);
        for (ssize_t i = 0; i < count; i++)
        {
            ret.append(QVariantMap {
                { QStringLiteral("value"), qfu(values[i]) },
                { QStringLiteral("text"), qfu(texts[i]) },
            });
            free(values[i]);
            free(texts[i]);
        }
        if (count >= 0)
        {
            free(values);
            free(texts);
        }
    }
    return ret;
}

bool ConfigOption::modified() const
{
    return m_config && value() != defaultValue();
}

void ConfigOption::reset()
{
    setValue(defaultValue());
}

void ConfigOption::onOptionChanged(const QString &name)
{
    if (name.isEmpty() || name == m_name)
        emit valueChanged();
}


SettingsBridge::SettingsBridge(qt_intf_t *intf, QObject *parent)
    : QObject(parent)
    , m_intf(intf)
{
    assert(!s_bridge);
    s_bridge = this;
}

SettingsBridge::~SettingsBridge()
{
    s_bridge = nullptr;
}

SettingsBridge *SettingsBridge::instance()
{
    return s_bridge;
}

void SettingsBridge::notify(const QString &name)
{
    emit optionChanged(name);
}

bool SettingsBridge::moduleExists(const QString &module)
{
    return module_exists(qtu(module));
}

bool SettingsBridge::hasModule(const QString &option, const QString &module)
{
    const QByteArray key = option.toUtf8();
    if (!config_FindConfig(key.constData()))
        return false;

    const QStringList list = splitModules(configString(key.constData()));
    return std::any_of(list.cbegin(), list.cend(), [&module](const QString &entry) {
        return moduleName(entry) == module;
    });
}

void SettingsBridge::setModule(const QString &option, const QString &module, bool enabled)
{
    const QByteArray key = option.toUtf8();
    if (!config_FindConfig(key.constData()) || hasModule(option, module) == enabled)
        return;

    QStringList list = splitModules(configString(key.constData()));
    if (enabled)
        list.append(module);
    else
        list.removeIf([&module](const QString &entry) { return moduleName(entry) == module; });

    config_PutPsz(key.constData(), qtu(list.join(QLatin1Char(':'))));
    notify(option);
}

bool SettingsBridge::hasInterface(const QString &intf)
{
    return config_ExistIntf(qtu(intf));
}

void SettingsBridge::setInterface(const QString &intf, bool enabled)
{
    if (hasInterface(intf) == enabled)
        return;

    if (enabled)
        config_AddIntf(qtu(intf));
    else
        config_RemoveIntf(qtu(intf));
    notify(QStringLiteral("extraintf"));
    notify(QStringLiteral("control"));
}

void SettingsBridge::syncFilter(const QString &chain, const QString &module, const QStringList &options)
{
    const bool modified = std::any_of(options.cbegin(), options.cend(), [](const QString &name) {
        ConfigOption option;
        option.setName(name);
        return option.modified();
    });
    setModule(chain, module, modified);
}

void SettingsBridge::resetOptions(const QStringList &options)
{
    for (const QString &name : options)
    {
        ConfigOption option;
        option.setName(name);
        option.reset();
    }
}

QString SettingsBridge::browseFile(const QString &current, bool save)
{
    if (save)
        return QFileDialog::getSaveFileName(nullptr, qtr("Select a file"), current);
    return QFileDialog::getOpenFileName(nullptr, qtr("Select a file"), current);
}

QString SettingsBridge::browseDirectory(const QString &current)
{
    return QFileDialog::getExistingDirectory(nullptr, qtr("Select a directory"), current);
}

bool SettingsBridge::hasDefaultVolume() const
{
    return defaultVolume() >= 0;
}

int SettingsBridge::defaultVolume() const
{
    const QString aout = configString("aout");

    if (aout.isEmpty() || aout == QLatin1String("any"))
    {
#ifdef _WIN32
        /* Every Windows output saves its volume, the first one stands for all */
        return config_GetFloat("mmdevice-volume") * 100.f + .5f;
#else
        return -1;
#endif
    }

#ifdef __linux__
    if (aout == QLatin1String("alsa") && module_exists("alsa"))
        return cbrtf(config_GetFloat("alsa-gain")) * 100.f + .5f;
#endif
#ifdef _WIN32
    if (aout == QLatin1String("mmdevice"))
        return config_GetFloat("mmdevice-volume") * 100.f + .5f;
    if (aout == QLatin1String("waveout"))
        return config_GetFloat("waveout-volume") * 100.f + .5f;
#endif
#ifdef __APPLE__
    if (aout == QLatin1String("auhal") && module_exists("auhal"))
        return (config_GetFloat("auhal-volume") * 100.f + .5f) / AOUT_VOLUME_DEFAULT;
#endif
    if (aout == QLatin1String("jack"))
        return cbrtf(config_GetFloat("jack-gain")) * 100.f + .5f;
#ifdef __OS2__
    if (aout == QLatin1String("kai"))
        return cbrtf(config_GetFloat("kai-gain")) * 100.f + .5f;
#endif
    return -1;
}

void SettingsBridge::setDefaultVolume(int percent)
{
    const QString aout = configString("aout");
    const auto matches = [&aout](const char *name) {
        return module_exists(name)
            && (aout.isEmpty() || aout == QLatin1String(name) || aout == QLatin1String("any"));
    };

    const float volume = percent / 100.f;
#if defined(_WIN32)
    if (matches("mmdevice"))
        config_PutFloat("mmdevice-volume", volume);
    if (matches("waveout"))
        config_PutFloat("waveout-volume", volume);
#elif defined(__APPLE__)
    if (matches("auhal"))
        config_PutFloat("auhal-volume", volume * AOUT_VOLUME_DEFAULT);
#elif defined(__OS2__)
    if (matches("kai"))
        config_PutFloat("kai-gain", powf(volume, 3));
#else
    if (matches("alsa"))
        config_PutFloat("alsa-gain", powf(volume, 3));
    if (matches("jack"))
        config_PutFloat("jack-gain", powf(volume, 3));
#endif
    emit optionChanged(QStringLiteral("aout"));
}

QVariantMap SettingsBridge::equalizerPreset(const QString &name)
{
    for (const eqz_preset_t &preset : eqz_preset_10b)
    {
        if (name != QLatin1String(preset.psz_name))
            continue;

        QVariantList bands;
        for (int i = 0; i < preset.i_band; i++)
            bands.append(std::round(preset.f_amp[i] * 10.f) / 10.f);
        return {
            { QStringLiteral("preamp"), preset.f_preamp },
            { QStringLiteral("bands"), bands },
        };
    }
    return {};
}

QString SettingsBridge::configDirectory() const
{
    char *dir = config_GetUserDir(VLC_CONFIG_DIR);
    QString ret = qfu(dir);
    free(dir);
    return ret;
}

void SettingsBridge::openConfigDirectory() const
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(configDirectory()));
}

void SettingsBridge::resetHotkeys()
{
    unsigned count;
    module_config_t *items = module_config_get(module_get_main(), &count);
    for (unsigned i = 0; i < count; i++)
    {
        const module_config_t &item = items[i];
        if (item.i_type != CONFIG_ITEM_KEY)
            continue;
        config_PutPsz(item.psz_name, item.orig.psz);
        emit optionChanged(qfu(item.psz_name));
    }
    module_config_free(items);
}

void SettingsBridge::resetAll()
{
    config_ResetAll();
    config_SaveConfigFile(m_intf);
    m_intf->mainSettings->clear();
    m_intf->preferencesResetPending = true;
    if (m_intf->p_mi)
    {
        m_intf->p_mi->reloadPrefs();
        m_intf->p_mi->reloadFromSettings();
    }
    emit optionChanged(QString());

    if (THEDP->questionDialog(qtr("VLC needs to be restarted for the reset to take full effect.\n\nRestart now?"),
                              qtr("Restart Required")) && m_intf->p_mi)
        emit m_intf->p_mi->askToQuit();
}

bool SettingsBridge::save()
{
    const bool ok = config_SaveConfigFile(m_intf) == 0;
    if (!ok)
        DialogErrorModel::getInstance(m_intf)->pushError(qtr("Cannot save Configuration"),
                                                         qtr("Preferences file could not be saved"));
    if (m_intf->p_mi)
        m_intf->p_mi->reloadPrefs();
    return ok;
}
