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
#ifndef SETTINGS_BRIDGE_HPP
#define SETTINGS_BRIDGE_HPP

#include <QObject>
#include <QVariant>
#include <QtQml>

#include "qt.hpp"

/**
 * ConfigOption exposes one VLC configuration item to QML. Writing `value`
 * stores it in the running configuration right away; SettingsBridge.save()
 * writes the configuration file.
 */
class ConfigOption : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged FINAL)
    Q_PROPERTY(bool available READ available NOTIFY nameChanged FINAL)
    Q_PROPERTY(Type type READ type NOTIFY nameChanged FINAL)
    Q_PROPERTY(QString text READ text NOTIFY nameChanged FINAL)
    Q_PROPERTY(QString longText READ longText NOTIFY nameChanged FINAL)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged FINAL)
    Q_PROPERTY(QVariant defaultValue READ defaultValue NOTIFY nameChanged FINAL)
    Q_PROPERTY(QVariant minimum READ minimum NOTIFY nameChanged FINAL)
    Q_PROPERTY(QVariant maximum READ maximum NOTIFY nameChanged FINAL)
    Q_PROPERTY(QVariantList choices READ choices NOTIFY nameChanged FINAL)
    Q_PROPERTY(bool modified READ modified NOTIFY valueChanged FINAL)

public:
    enum Type
    {
        TYPE_NONE,
        TYPE_BOOL,
        TYPE_INTEGER,
        TYPE_COLOR,
        TYPE_FLOAT,
        TYPE_STRING,
        TYPE_PASSWORD,
        TYPE_FILE,
        TYPE_DIRECTORY,
        TYPE_FONT,
        TYPE_MODULE
    };
    Q_ENUM(Type)

    explicit ConfigOption(QObject *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &name);

    bool available() const { return m_config != nullptr; }
    Type type() const;
    QString text() const;
    QString longText() const;

    QVariant value() const;
    void setValue(const QVariant &value);

    QVariant defaultValue() const;
    QVariant minimum() const;
    QVariant maximum() const;

    /// list of { value, text } maps, as the module declares them
    QVariantList choices() const;

    bool modified() const;

    Q_INVOKABLE void reset();

signals:
    void nameChanged();
    void valueChanged();

private:
    void onOptionChanged(const QString &name);

    QString m_name;
    QByteArray m_key;
    module_config_t *m_config = nullptr;
};

class SettingsBridge : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool hasDefaultVolume READ hasDefaultVolume NOTIFY optionChanged FINAL)
    Q_PROPERTY(QString configDirectory READ configDirectory CONSTANT FINAL)

public:
    explicit SettingsBridge(qt_intf_t *intf, QObject *parent = nullptr);
    ~SettingsBridge() override;

    static SettingsBridge *instance();

    Q_INVOKABLE static bool moduleExists(const QString &module);

    /// whether `module` is part of the ':' separated list stored in `option`
    Q_INVOKABLE static bool hasModule(const QString &option, const QString &module);
    Q_INVOKABLE void setModule(const QString &option, const QString &module, bool enabled);

    /// interfaces started next to the main one, such as "audioscrobbler" or "http"
    Q_INVOKABLE static bool hasInterface(const QString &intf);
    Q_INVOKABLE void setInterface(const QString &intf, bool enabled);

    /// enables `module` in `chain` when one of `options` differs from its default
    Q_INVOKABLE void syncFilter(const QString &chain, const QString &module, const QStringList &options);
    Q_INVOKABLE void resetOptions(const QStringList &options);

    /// native file pickers; they return an empty string when cancelled
    Q_INVOKABLE static QString browseFile(const QString &current, bool save);
    Q_INVOKABLE static QString browseDirectory(const QString &current);

    bool hasDefaultVolume() const;
    Q_INVOKABLE int defaultVolume() const;
    Q_INVOKABLE void setDefaultVolume(int percent);

    /// { preamp, bands } of a built-in equalizer preset
    Q_INVOKABLE static QVariantMap equalizerPreset(const QString &name);

    QString configDirectory() const;
    Q_INVOKABLE void openConfigDirectory() const;

    Q_INVOKABLE void resetHotkeys();
    Q_INVOKABLE void resetAll();

    Q_INVOKABLE bool save();

    /// re-reads every option, after another dialog wrote the configuration
    Q_INVOKABLE void refresh() { emit optionChanged(QString()); }

    void notify(const QString &name);

signals:
    void optionChanged(const QString &name);

private:
    qt_intf_t *m_intf;
};

#endif // SETTINGS_BRIDGE_HPP
