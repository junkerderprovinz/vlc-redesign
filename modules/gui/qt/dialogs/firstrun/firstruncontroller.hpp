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

#ifndef VLC_FIRSTRUNCONTROLLER_HPP
#define VLC_FIRSTRUNCONTROLLER_HPP

#include <QObject>
#include <QString>
#include <QStringList>

#include "util/color_scheme_model.hpp"

class MainCtx;

Q_MOC_INCLUDE("maininterface/mainctx.hpp")

/**
 * Backs the first run dialog: holds the choices made in it and applies them
 * to the configuration once the dialog is finished or skipped.
 */
class FirstRunController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged FINAL)
    Q_PROPERTY(bool metadataNetworkAccess MEMBER m_metadataNetworkAccess NOTIFY metadataNetworkAccessChanged FINAL)
    Q_PROPERTY(bool classicLayout MEMBER m_classicLayout NOTIFY classicLayoutChanged FINAL)

public:
    explicit FirstRunController( QObject *parent = nullptr );

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx( MainCtx* ctx );

    QString folder() const { return m_folder; }
    void setFolder( const QString& folder );

    Q_INVOKABLE void browseFolder();
    Q_INVOKABLE void setColorScheme( ColorSchemeModel::ColorScheme scheme );
    Q_INVOKABLE QStringList hotkey( const QString& name ) const;

    Q_INVOKABLE void finish();
    Q_INVOKABLE void skip();

signals:
    void ctxChanged();
    void folderChanged();
    void metadataNetworkAccessChanged();
    void classicLayoutChanged();

private:
    void apply();
    void addFolders();

    MainCtx* m_ctx = nullptr;
    QString m_folder;
    QString m_defaultFolder;
    bool m_metadataNetworkAccess = true;
    bool m_classicLayout = false;
};

#endif // VLC_FIRSTRUNCONTROLLER_HPP
