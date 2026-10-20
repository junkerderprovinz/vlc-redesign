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

#include "subtitles_model.hpp"

#include <vlc_common.h>
#include <vlc_input_item.h>
#include <vlc_interface.h>
#include <vlc_playlist.h>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"
#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"
#include "playlist/media.hpp"

#include <QCollator>
#include <QDir>
#include <QFileDialog>
#include <QFileInfo>
#include <QRegularExpression>

#include <algorithm>

namespace {

QString normalizedName(const QString &fileName)
{
    QString name = QFileInfo(fileName).completeBaseName().toLower();
    name.remove(QRegularExpression(QStringLiteral("[^\\p{L}\\p{N}]")));
    return name;
}

/* Season and episode numbers, such as "S01E02" or "1x02", or an invalid pair. */
std::pair<int, int> episodeOf(const QString &fileName)
{
    static const QRegularExpression patterns[] = {
        QRegularExpression(QStringLiteral("s(\\d{1,2})[ ._-]?e(\\d{1,3})"),
                           QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral("(?:^|\\D)(\\d{1,2})x(\\d{2,3})(?:\\D|$)"),
                           QRegularExpression::CaseInsensitiveOption),
    };
    for (const QRegularExpression &pattern : patterns)
    {
        const QRegularExpressionMatch match = pattern.match(fileName);
        if (match.hasMatch())
            return { match.captured(1).toInt(), match.captured(2).toInt() };
    }
    return { -1, -1 };
}

/* How well a subtitle file name fits a media file name, 0 when it does not. */
int matchScore(const QString &media, const QString &subtitle)
{
    const auto mediaEpisode = episodeOf(media);
    const auto subtitleEpisode = episodeOf(subtitle);
    if (mediaEpisode.first >= 0 && subtitleEpisode.first >= 0)
        return mediaEpisode == subtitleEpisode ? 3 : 0;

    const QString mediaName = normalizedName(media);
    const QString subtitleName = normalizedName(subtitle);
    if (mediaName.isEmpty() || subtitleName.isEmpty())
        return 0;
    if (subtitleName.startsWith(mediaName))
        return 2;
    if (mediaName.contains(subtitleName))
        return 1;
    return 0;
}

bool sameMedia(const QUrl &a, const QUrl &b)
{
    if (a.isLocalFile() && b.isLocalFile())
        return QDir::cleanPath(a.toLocalFile()) == QDir::cleanPath(b.toLocalFile());
    return a == b;
}

QString displayName(const QUrl &url)
{
    const QString name = url.fileName();
    return name.isEmpty() ? url.toDisplayString() : name;
}

bool hasSlave(input_item_t *item, const char *uri)
{
    vlc_mutex_locker locker(&item->lock);
    for (int i = 0; i < item->i_slaves; ++i)
        if (!strcmp(item->pp_slaves[i]->psz_uri, uri))
            return true;
    return false;
}

void addSubtitle(input_item_t *item, const QUrl &subtitle)
{
    const QByteArray uri = subtitle.toEncoded();
    if (hasSlave(item, uri.constData()))
        return;

    /* the preparser replaces the slaves of an item, a local file is also
     * given as an option so that it is still loaded after preparsing */
    if (subtitle.isLocalFile())
    {
        const QByteArray option = ":sub-file=" + subtitle.toLocalFile().toUtf8();
        input_item_AddOption(item, option.constData(), VLC_INPUT_OPTION_TRUSTED);
    }

    input_item_slave_t *slave = input_item_slave_New(uri.constData(), SLAVE_TYPE_SPU, SLAVE_PRIORITY_USER);
    if (slave && input_item_AddSlave(item, slave) != VLC_SUCCESS)
        input_item_slave_Delete(slave);
}

}

SubtitlesModel::SubtitlesModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SubtitlesModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_rows.size();
}

QVariant SubtitlesModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};

    const Row &row = m_rows[index.row()];
    switch (role)
    {
    case MEDIA_NAME:
        return row.mediaName;
    case Qt::DisplayRole:
    case SUBTITLE_NAME:
        return row.subtitle.isEmpty() ? QString() : displayName(row.subtitle);
    case SUBTITLE_URL:
        return row.subtitle;
    case CHECKED:
        return row.checked;
    default:
        return {};
    }
}

QHash<int, QByteArray> SubtitlesModel::roleNames() const
{
    return {
        { MEDIA_NAME, "mediaName" },
        { SUBTITLE_NAME, "subtitleName" },
        { SUBTITLE_URL, "subtitleUrl" },
        { CHECKED, "checked" },
    };
}

void SubtitlesModel::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
    refresh();
}

void SubtitlesModel::setTarget(Target target)
{
    if (m_target == target)
        return;
    const bool wasPairing = pairing();
    m_target = target;
    emit targetChanged();
    if (wasPairing != pairing())
        emit pairingChanged();
    rebuild();
}

void SubtitlesModel::setOrigin(Origin origin)
{
    if (m_origin == origin)
        return;
    const bool wasPairing = pairing();
    m_origin = origin;
    emit originChanged();
    if (wasPairing != pairing())
        emit pairingChanged();
    rebuild();
}

void SubtitlesModel::setFolder(const QUrl &folder)
{
    if (m_folder == folder)
        return;
    m_folder = folder;
    m_subtitles = listFolder(m_folder, EXTENSIONS_SUBTITLE);
    emit folderChanged();
    rebuild();
}

QString SubtitlesModel::folderLabel() const
{
    if (!m_folder.isLocalFile())
        return m_folder.toDisplayString();

    QString path = QDir::cleanPath(m_folder.toLocalFile());
    const QString home = QDir::cleanPath(QDir::homePath());
    if (path.startsWith(home + QLatin1Char('/')))
        path = path.mid(home.size() + 1);
    return QDir::toNativeSeparators(path).split(QDir::separator(), Qt::SkipEmptyParts)
                                         .join(QStringLiteral(" / "));
}

void SubtitlesModel::setLink(const QString &link)
{
    if (m_link == link)
        return;
    m_link = link;
    emit linkChanged();
    if (m_origin == ORIGIN_LINK)
        rebuild();
}

bool SubtitlesModel::canApply() const
{
    if (pairing())
        return std::any_of(m_rows.cbegin(), m_rows.cend(), [](const Row &row) {
            return !row.subtitle.isEmpty();
        });
    return hasMedia() && std::any_of(m_rows.cbegin(), m_rows.cend(), [](const Row &row) {
        return row.checked;
    });
}

void SubtitlesModel::refresh()
{
    if (!m_ctx)
        return;

    qt_intf_t *p_intf = m_ctx->getIntf();
    QUrl media;
    if (input_item_t *item = THEMIM->getInput())
    {
        char *uri = input_item_GetURI(item);
        if (uri)
            media = QUrl::fromEncoded(uri);
        free(uri);
    }

    if (media != m_media)
    {
        m_media = media;
        emit mediaChanged();
    }

    const QUrl folder = m_media.isLocalFile()
                      ? QUrl::fromLocalFile(QFileInfo(m_media.toLocalFile()).absolutePath())
                      : m_folder;
    if (folder != m_folder)
    {
        m_folder = folder;
        emit folderChanged();
    }
    m_subtitles = listFolder(m_folder, EXTENSIONS_SUBTITLE);
    rebuild();
}

void SubtitlesModel::toggle(int row)
{
    if (row < 0 || row >= m_rows.size() || pairing())
        return;
    m_rows[row].checked = !m_rows[row].checked;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { CHECKED });
    emit canApplyChanged();
}

void SubtitlesModel::setSubtitle(int row, const QUrl &subtitle)
{
    if (row < 0 || row >= m_rows.size() || !pairing())
        return;
    m_rows[row].subtitle = subtitle;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { SUBTITLE_NAME, SUBTITLE_URL });
    emit canApplyChanged();
}

QVariantList SubtitlesModel::candidates(int row) const
{
    QVariantList list;
    if (row < 0 || row >= m_rows.size())
        return list;

    for (const QUrl &subtitle : rankedSubtitles(m_rows[row].media))
        list.push_back(QVariantMap{ { "name", displayName(subtitle) }, { "url", subtitle } });
    return list;
}

void SubtitlesModel::browseFolder()
{
    const QUrl folder = QFileDialog::getExistingDirectoryUrl(nullptr, qtr("Subtitles Folder"),
                                                             m_folder, QFileDialog::ShowDirsOnly,
                                                             { QStringLiteral("file") });
    if (!folder.isEmpty())
        setFolder(folder);
}

void SubtitlesModel::apply()
{
    if (!m_ctx || !canApply())
        return;

    if (!pairing())
    {
        qt_intf_t *p_intf = m_ctx->getIntf();
        bool select = true;
        for (const Row &row : m_rows)
        {
            if (!row.checked)
                continue;
            THEMIM->AddAssociatedMedia(SPU_ES, QString::fromUtf8(row.subtitle.toEncoded()), select, true, false);
            select = false;
        }
        return;
    }

    qt_intf_t *p_intf = m_ctx->getIntf();
    QVector<Row> pending;
    for (const Row &row : m_rows)
    {
        if (row.subtitle.isEmpty())
            continue;
        /* the player records the slave in the playing item itself */
        if (sameMedia(row.media, m_media))
            THEMIM->AddAssociatedMedia(SPU_ES, QString::fromUtf8(row.subtitle.toEncoded()), true, true, false);
        else
            pending.push_back(row);
    }

    QVector<bool> queued(pending.size(), false);
    vlc_playlist_t *playlist = p_intf->p_playlist;
    vlc_playlist_Lock(playlist);
    const size_t count = vlc_playlist_Count(playlist);
    for (size_t i = 0; i < count; ++i)
    {
        input_item_t *item = vlc_playlist_item_GetMedia(vlc_playlist_Get(playlist, i));
        char *uri = input_item_GetURI(item);
        if (!uri)
            continue;
        const QUrl url = QUrl::fromEncoded(uri);
        free(uri);

        for (int j = 0; j < pending.size(); ++j)
        {
            if (!sameMedia(url, pending[j].media))
                continue;
            addSubtitle(item, pending[j].subtitle);
            queued[j] = true;
        }
    }
    vlc_playlist_Unlock(playlist);

    QVector<vlc::playlist::Media> missing;
    for (int j = 0; j < pending.size(); ++j)
    {
        if (queued[j])
            continue;
        vlc::playlist::Media media(QString::fromUtf8(pending[j].media.toEncoded()), pending[j].mediaName);
        addSubtitle(media.raw(), pending[j].subtitle);
        missing.push_back(media);
    }
    if (!missing.isEmpty())
        THEMPL->append(missing, false);
}

void SubtitlesModel::rebuild()
{
    beginResetModel();
    m_rows.clear();

    if (m_origin == ORIGIN_LINK)
    {
        const QUrl url = QUrl::fromUserInput(m_link.trimmed());
        if (url.isValid() && !url.fileName().isEmpty() && !m_link.trimmed().isEmpty())
            m_rows.push_back({ {}, m_media, url, true });
    }
    else if (m_origin == ORIGIN_COMPUTER && m_target == TARGET_FILE)
    {
        const QVector<QUrl> ranked = rankedSubtitles(m_media);
        for (const QUrl &subtitle : ranked)
            m_rows.push_back({ {}, m_media, subtitle, false });
        for (const QUrl &subtitle : m_subtitles)
            if (!ranked.contains(subtitle))
                m_rows.push_back({ {}, m_media, subtitle, false });
        if (!ranked.isEmpty())
            m_rows.first().checked = true;
    }
    else if (m_origin == ORIGIN_COMPUTER && m_target == TARGET_FOLDER)
    {
        for (const QUrl &media : listFolder(m_folder, EXTENSIONS_VIDEO))
        {
            const QVector<QUrl> ranked = rankedSubtitles(media);
            m_rows.push_back({ displayName(media), media,
                               ranked.isEmpty() ? QUrl() : ranked.first(), false });
        }
    }
    else if (m_origin == ORIGIN_COMPUTER && m_target == TARGET_QUEUE && m_ctx)
    {
        qt_intf_t *p_intf = m_ctx->getIntf();
        vlc_playlist_t *playlist = p_intf->p_playlist;
        vlc_playlist_Lock(playlist);
        const size_t count = vlc_playlist_Count(playlist);
        for (size_t i = 0; i < count; ++i)
        {
            input_item_t *item = vlc_playlist_item_GetMedia(vlc_playlist_Get(playlist, i));
            char *uri = input_item_GetURI(item);
            char *name = input_item_GetName(item);
            if (uri)
            {
                const QUrl media = QUrl::fromEncoded(uri);
                m_rows.push_back({ name ? qfu(name) : displayName(media), media, {}, false });
            }
            free(uri);
            free(name);
        }
        vlc_playlist_Unlock(playlist);

        for (Row &row : m_rows)
        {
            const QVector<QUrl> ranked = rankedSubtitles(row.media);
            if (!ranked.isEmpty())
                row.subtitle = ranked.first();
        }
    }

    endResetModel();
    emit canApplyChanged();
}

QVector<QUrl> SubtitlesModel::listFolder(const QUrl &folder, const char *extensions) const
{
    QVector<QUrl> files;
    if (!folder.isLocalFile())
        return files;

    const QStringList filters = qfu(extensions).split(QLatin1Char(';'), Qt::SkipEmptyParts);
    QFileInfoList entries = QDir(folder.toLocalFile()).entryInfoList(filters, QDir::Files | QDir::Readable);

    QCollator collator;
    collator.setNumericMode(true);
    std::sort(entries.begin(), entries.end(), [&collator](const QFileInfo &a, const QFileInfo &b) {
        return collator.compare(a.fileName(), b.fileName()) < 0;
    });

    for (const QFileInfo &entry : entries)
        files.push_back(QUrl::fromLocalFile(entry.absoluteFilePath()));
    return files;
}

QVector<QUrl> SubtitlesModel::rankedSubtitles(const QUrl &media) const
{
    if (media.isEmpty())
        return {};

    const QString mediaName = media.fileName();
    QVector<std::pair<int, QUrl>> scored;
    for (const QUrl &subtitle : m_subtitles)
    {
        const int score = matchScore(mediaName, subtitle.fileName());
        if (score > 0)
            scored.push_back({ score, subtitle });
    }
    std::stable_sort(scored.begin(), scored.end(), [](const auto &a, const auto &b) {
        return a.first > b.first;
    });

    QVector<QUrl> ranked;
    for (const auto &entry : scored)
        ranked.push_back(entry.second);
    return ranked;
}
