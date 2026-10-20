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

#include "hotkeys_model.hpp"

#include <vlc_common.h>
#include <vlc_modules.h>
#include <vlc_plugin.h>
#include <vlc_actions.h>
#include <vlc_configuration.h>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"
#include "util/vlchotkeyconverter.hpp"

#include <QKeyEvent>
#include <QRegularExpression>

#include <algorithm>

namespace {

struct SectionEntries
{
    const char *title;
    std::initializer_list<const char *> names;
};

/* Names ending with '*' match every option starting with that prefix. */
const SectionEntries sections[] = {
    { N_("Basic"), { "toggle-fullscreen", "leave-fullscreen", "position", "intf-show" } },
    { N_("Playback"), { "play-pause", "pause", "play", "stop", "next", "prev",
                        "program-sid-next", "program-sid-prev", "faster", "slower",
                        "rate-normal", "rate-faster-fine", "rate-slower-fine",
                        "jump+extrashort", "jump-extrashort", "jump+short", "jump-short",
                        "jump+medium", "jump-medium", "jump+long", "jump-long",
                        "frame-next", "frame-previous", "random", "loop", "record",
                        "title-prev", "title-next", "chapter-prev", "chapter-next",
                        "disc-menu", "clear-playlist" } },
    { N_("Audio"), { "vol-up", "vol-down", "vol-mute", "audio-track", "audiodevice-cycle",
                     "audiodelay-up", "audiodelay-down" } },
    { N_("Video"), { "aspect-ratio", "crop", "zoom", "unzoom", "snapshot", "deinterlace",
                     "deinterlace-mode", "toggle-autoscale", "incr-scalefactor",
                     "decr-scalefactor", "wallpaper", "zoom-*", "crop-*", "uncrop-*",
                     "projection-toggle", "viewpoint-*" } },
    { N_("Subtitles"), { "subtitle-track", "subtitle-revtrack", "subtitle-toggle",
                         "subtitle-control-secondary", "subdelay-up", "subdelay-down",
                         "subsync-*", "subpos-*", "subtitle-text-scale-*" } },
    { N_("Navigation"), { "nav-*" } },
    { N_("Interface"), { "intf-boss", "intf-popup-menu", "quit" } },
    { N_("Bookmarks"), { "set-bookmark*", "play-bookmark*" } },
};

/* Sort key of an action: section index, then position inside the section. */
std::pair<int, int> placeOf(const char *action)
{
    int sectionIndex = 0;
    for (const SectionEntries &section : sections)
    {
        int entryIndex = 0;
        for (const char *entry : section.names)
        {
            const size_t len = strlen(entry);
            if (entry[len - 1] == '*' ? !strncmp(action, entry, len - 1)
                                      : !strcmp(action, entry))
                return { sectionIndex, entryIndex };
            ++entryIndex;
        }
        ++sectionIndex;
    }
    return { sectionIndex, 0 };
}

QStringList splitKeys(const char *value)
{
    if (value == nullptr)
        return {};
    return qfu(value).split('\t', Qt::SkipEmptyParts);
}

}

HotkeysModel::HotkeysModel(QObject *parent)
    : QAbstractListModel(parent)
{
    reload();
}

void HotkeysModel::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
}

int HotkeysModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_rows.size();
}

QVariant HotkeysModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};

    const Action &action = m_actions[m_rows[index.row()]];
    switch (role)
    {
    case SECTION:
        return action.section;
    case Qt::DisplayRole:
    case LABEL:
        return action.label;
    case HOTKEY:
        return displayKeys(action.normal.keys);
    case GLOBAL_HOTKEY:
        return displayKeys(action.global.keys);
    case HOTKEY_MODIFIED:
        return action.normal.keys != action.normal.defaults;
    case GLOBAL_HOTKEY_MODIFIED:
        return action.global.keys != action.global.defaults;
    default:
        return {};
    }
}

QHash<int, QByteArray> HotkeysModel::roleNames() const
{
    return {
        { SECTION, "section" },
        { LABEL, "label" },
        { HOTKEY, "hotkey" },
        { GLOBAL_HOTKEY, "globalHotkey" },
        { HOTKEY_MODIFIED, "hotkeyModified" },
        { GLOBAL_HOTKEY_MODIFIED, "globalHotkeyModified" },
    };
}

bool HotkeysModel::isModified() const
{
    return std::any_of(m_actions.cbegin(), m_actions.cend(), [](const Action &action) {
        return action.normal.keys != action.normal.saved
            || action.global.keys != action.global.saved;
    });
}

void HotkeysModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    beginResetModel();
    filterRows();
    endResetModel();
    emit filterChanged();
}

void HotkeysModel::setFilterField(FilterField field)
{
    if (m_filterField == field)
        return;
    m_filterField = field;
    beginResetModel();
    filterRows();
    endResetModel();
    emit filterChanged();
}

QString HotkeysModel::keyFromEvent(int key, int modifiers, const QString &text) const
{
    switch (key)
    {
    case Qt::Key_Shift:
    case Qt::Key_Control:
    case Qt::Key_Meta:
    case Qt::Key_Alt:
    case Qt::Key_AltGr:
    case Qt::Key_CapsLock:
    case Qt::Key_unknown:
        return {};
    default:
        break;
    }

    QKeyEvent event(QEvent::KeyPress, key, Qt::KeyboardModifiers(modifiers), text);
    const int vlcKey = qtEventToVLCKey(&event);
    if ((vlcKey & ~KEY_MODIFIER) == KEY_UNSET)
        return {};
    return VLCKeyToString(vlcKey, false);
}

QString HotkeysModel::conflictingAction(int row, bool global, const QString &key) const
{
    if (key.isEmpty() || row < 0 || row >= m_rows.size())
        return {};

    const int self = m_rows[row];
    for (int i = 0; i < m_actions.size(); ++i)
    {
        if (i == self)
            continue;
        const Binding &other = global ? m_actions[i].global : m_actions[i].normal;
        if (other.keys.contains(key))
            return m_actions[i].label;
    }
    return {};
}

void HotkeysModel::assign(int row, bool global, const QString &key)
{
    if (key.isEmpty() || row < 0 || row >= m_rows.size())
        return;
    setKeys(m_rows[row], global, QStringList{ key });
}

void HotkeysModel::unset(int row, bool global)
{
    if (row < 0 || row >= m_rows.size())
        return;
    setKeys(m_rows[row], global, {});
}

void HotkeysModel::reset(int row, bool global)
{
    if (row < 0 || row >= m_rows.size())
        return;
    setKeys(m_rows[row], global, binding(row, global).defaults);
}

void HotkeysModel::reload()
{
    beginResetModel();
    m_actions.clear();

    module_t *main = module_get_main();
    unsigned count;
    module_config_t *config = module_config_get(main, &count);

    QVector<std::pair<std::pair<int, int>, Action>> sorted;
    for (unsigned i = 0; i < count; ++i)
    {
        const module_config_t &item = config[i];
        if (item.i_type != CONFIG_ITEM_KEY || !strncmp(item.psz_name, "global-", 7))
            continue;

        Action action;
        action.label = qfut(item.psz_text);
        action.normal.option = item.psz_name;
        action.normal.keys = action.normal.saved = splitKeys(item.value.psz);
        action.normal.defaults = splitKeys(item.orig.psz);
        action.global.option = QByteArray("global-") + item.psz_name;

        const auto place = placeOf(item.psz_name + strlen("key-"));
        action.section = place.first < int(ARRAY_SIZE(sections))
                       ? qfut(sections[place.first].title) : qtr("Other");
        sorted.push_back({ place, action });
    }

    for (unsigned i = 0; i < count; ++i)
    {
        const module_config_t &item = config[i];
        if (item.i_type != CONFIG_ITEM_KEY || strncmp(item.psz_name, "global-", 7))
            continue;

        for (auto &entry : sorted)
        {
            Binding &global = entry.second.global;
            if (global.option == item.psz_name)
            {
                global.keys = global.saved = splitKeys(item.value.psz);
                global.defaults = splitKeys(item.orig.psz);
                break;
            }
        }
    }
    module_config_free(config);

    std::stable_sort(sorted.begin(), sorted.end(), [](const auto &a, const auto &b) {
        return a.first < b.first;
    });
    for (const auto &entry : sorted)
        m_actions.push_back(entry.second);

    filterRows();

    endResetModel();
    emit modifiedChanged();
}

void HotkeysModel::apply()
{
    for (Action &action : m_actions)
    {
        for (Binding *b : { &action.normal, &action.global })
        {
            if (b->keys == b->saved)
                continue;
            config_PutPsz(b->option.constData(), qtu(b->keys.join('\t')));
            b->saved = b->keys;
        }
    }

    if (m_ctx)
        config_SaveConfigFile(m_ctx->getIntf());
    emit modifiedChanged();
}

const HotkeysModel::Binding &HotkeysModel::binding(int row, bool global) const
{
    const Action &action = m_actions[m_rows[row]];
    return global ? action.global : action.normal;
}

QString HotkeysModel::displayKeys(const QStringList &keys) const
{
    QStringList names;
    for (const QString &key : keys)
    {
        QString name = VLCKeyToString(vlc_str2keycode(qtu(key)), true);
        /* letter keys are named in lower case, keyboards show them in upper case */
        if (name.size() - name.lastIndexOf(QLatin1Char('+')) == 2)
            name.back() = name.back().toUpper();
        static const QRegularExpression separator(QStringLiteral("(?<=[^+\\s])\\+(?=\\S)"));
        names.push_back(name.replace(separator, QStringLiteral(" + ")));
    }
    return names.join(QStringLiteral(", "));
}

bool HotkeysModel::matchesFilter(const Action &action) const
{
    if (m_filterText.isEmpty())
        return true;

    const auto matches = [this](const QString &text) {
        return text.contains(m_filterText, Qt::CaseInsensitive);
    };

    switch (m_filterField)
    {
    case ACTION_FIELD:
        return matches(action.label);
    case HOTKEY_FIELD:
        return matches(displayKeys(action.normal.keys));
    case GLOBAL_HOTKEY_FIELD:
        return matches(displayKeys(action.global.keys));
    case ANY_FIELD:
    default:
        return matches(action.label) || matches(displayKeys(action.normal.keys))
            || matches(displayKeys(action.global.keys));
    }
}

void HotkeysModel::filterRows()
{
    m_rows.clear();
    for (int i = 0; i < m_actions.size(); ++i)
        if (matchesFilter(m_actions[i]))
            m_rows.push_back(i);
}

void HotkeysModel::setKeys(int actionIndex, bool global, const QStringList &keys)
{
    const bool wasModified = isModified();

    for (int i = 0; i < m_actions.size(); ++i)
    {
        if (i == actionIndex)
            continue;
        Binding &other = global ? m_actions[i].global : m_actions[i].normal;
        bool changed = false;
        for (const QString &key : keys)
            changed |= other.keys.removeAll(key) > 0;
        if (changed)
            notifyRow(i);
    }

    Action &action = m_actions[actionIndex];
    (global ? action.global : action.normal).keys = keys;
    notifyRow(actionIndex);

    if (wasModified != isModified())
        emit modifiedChanged();
}

void HotkeysModel::notifyRow(int actionIndex)
{
    const int row = m_rows.indexOf(actionIndex);
    if (row < 0)
        return;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx);
}
