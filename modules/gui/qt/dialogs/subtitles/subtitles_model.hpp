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

#ifndef SUBTITLES_MODEL_HPP
#define SUBTITLES_MODEL_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QAbstractListModel>
#include <QUrl>
#include <QVector>

Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class MainCtx;

/**
 * Subtitle files offered for the playing file, or paired with the media of
 * a folder or of the play queue, and attached to them as subtitle slaves.
 */
class SubtitlesModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(Target target READ target WRITE setTarget NOTIFY targetChanged FINAL)
    Q_PROPERTY(Origin origin READ origin WRITE setOrigin NOTIFY originChanged FINAL)
    Q_PROPERTY(QUrl folder READ folder WRITE setFolder NOTIFY folderChanged FINAL)
    Q_PROPERTY(QString folderLabel READ folderLabel NOTIFY folderChanged FINAL)
    Q_PROPERTY(QString link READ link WRITE setLink NOTIFY linkChanged FINAL)
    Q_PROPERTY(bool pairing READ pairing NOTIFY pairingChanged FINAL)
    Q_PROPERTY(bool hasMedia READ hasMedia NOTIFY mediaChanged FINAL)
    Q_PROPERTY(bool canApply READ canApply NOTIFY canApplyChanged FINAL)

public:
    enum Target {
        TARGET_FILE,
        TARGET_FOLDER,
        TARGET_QUEUE,
    };
    Q_ENUM(Target)

    enum Origin {
        ORIGIN_COMPUTER,
        ORIGIN_OPENSUBTITLES,
        ORIGIN_LINK,
    };
    Q_ENUM(Origin)

    enum Roles {
        MEDIA_NAME = Qt::UserRole + 1,
        SUBTITLE_NAME,
        SUBTITLE_URL,
        CHECKED,
    };
    Q_ENUM(Roles)

    explicit SubtitlesModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    MainCtx *getCtx() const { return m_ctx; }
    void setCtx(MainCtx *ctx);

    Target target() const { return m_target; }
    void setTarget(Target target);

    Origin origin() const { return m_origin; }
    void setOrigin(Origin origin);

    QUrl folder() const { return m_folder; }
    void setFolder(const QUrl &folder);
    QString folderLabel() const;

    QString link() const { return m_link; }
    void setLink(const QString &link);

    bool pairing() const { return m_origin == ORIGIN_COMPUTER && m_target != TARGET_FILE; }
    bool hasMedia() const { return m_media.isValid(); }
    bool canApply() const;

    /** Reads the playing media, the folder content and the play queue again. */
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggle(int row);
    Q_INVOKABLE void setSubtitle(int row, const QUrl &subtitle);
    /** Subtitle files that match the media of @a row, best first, as {name, url} maps. */
    Q_INVOKABLE QVariantList candidates(int row) const;
    Q_INVOKABLE void browseFolder();
    Q_INVOKABLE void apply();

signals:
    void ctxChanged();
    void targetChanged();
    void originChanged();
    void pairingChanged();
    void folderChanged();
    void linkChanged();
    void mediaChanged();
    void canApplyChanged();

private:
    struct Row {
        QString mediaName;
        QUrl media;
        QUrl subtitle;
        bool checked = false;
    };

    void rebuild();
    QVector<QUrl> listFolder(const QUrl &folder, const char *extensions) const;
    QVector<QUrl> rankedSubtitles(const QUrl &media) const;

    MainCtx *m_ctx = nullptr;
    Target m_target = TARGET_FILE;
    Origin m_origin = ORIGIN_COMPUTER;
    QUrl m_folder;
    QString m_link;
    QUrl m_media;
    QVector<QUrl> m_subtitles;
    QVector<Row> m_rows;
};

#endif // SUBTITLES_MODEL_HPP
