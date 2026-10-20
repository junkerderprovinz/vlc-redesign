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

#ifndef HOTKEYS_MODEL_HPP
#define HOTKEYS_MODEL_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QAbstractListModel>
#include <QStringList>
#include <QVector>

Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class MainCtx;

/**
 * List of the core hotkey options (key-* and global-key-*), grouped in
 * sections, editable and written back to the configuration.
 */
class HotkeysModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(bool modified READ isModified NOTIFY modifiedChanged FINAL)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterChanged FINAL)
    Q_PROPERTY(FilterField filterField READ filterField WRITE setFilterField NOTIFY filterChanged FINAL)

public:
    enum Roles {
        SECTION = Qt::UserRole + 1,
        LABEL,
        HOTKEY,
        GLOBAL_HOTKEY,
        HOTKEY_MODIFIED,
        GLOBAL_HOTKEY_MODIFIED,
    };
    Q_ENUM(Roles)

    enum FilterField {
        ANY_FIELD,
        ACTION_FIELD,
        HOTKEY_FIELD,
        GLOBAL_HOTKEY_FIELD,
    };
    Q_ENUM(FilterField)

    explicit HotkeysModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    MainCtx *getCtx() const { return m_ctx; }
    void setCtx(MainCtx *ctx);

    bool isModified() const;

    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);
    FilterField filterField() const { return m_filterField; }
    void setFilterField(FilterField field);

    /**
     * Returns the VLC name of the key combination of a key event, or an
     * empty string for a lone modifier key.
     */
    Q_INVOKABLE QString keyFromEvent(int key, int modifiers, const QString &text) const;

    /** Returns the action already using @a key in that column, or an empty string. */
    Q_INVOKABLE QString conflictingAction(int row, bool global, const QString &key) const;

    /** Binds @a key to the action, removing it from every other action of that column. */
    Q_INVOKABLE void assign(int row, bool global, const QString &key);
    Q_INVOKABLE void unset(int row, bool global);
    Q_INVOKABLE void reset(int row, bool global);

    Q_INVOKABLE void reload();
    Q_INVOKABLE void apply();

signals:
    void ctxChanged();
    void modifiedChanged();
    void filterChanged();

private:
    struct Binding {
        QByteArray option;
        QStringList keys;
        QStringList saved;
        QStringList defaults;
    };

    struct Action {
        QString section;
        QString label;
        Binding normal;
        Binding global;
    };

    const Binding &binding(int row, bool global) const;
    void setKeys(int actionIndex, bool global, const QStringList &keys);
    QString displayKeys(const QStringList &keys) const;
    bool matchesFilter(const Action &action) const;
    void filterRows();
    void notifyRow(int actionIndex);

    MainCtx *m_ctx = nullptr;
    QVector<Action> m_actions;
    QVector<int> m_rows;
    QString m_filterText;
    FilterField m_filterField = ANY_FIELD;
};

#endif // HOTKEYS_MODEL_HPP
