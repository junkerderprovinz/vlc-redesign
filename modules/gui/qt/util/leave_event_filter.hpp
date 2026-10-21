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
#ifndef LEAVEEVENTFILTER_HPP
#define LEAVEEVENTFILTER_HPP

#include <QObject>
#include <QPointer>

/**
 * @brief The LeaveEventFilter class reports when the pointer leaves the
 * target, usually a window. Hover handlers cannot tell this reliably, as
 * items that accept hover events hide the pointer from the items below.
 *
 *  LeaveEventFilter {
 *      target: MainCtx.intfMainWindow
 *      onExited: {
 *          //do stuff
 *      }
 *  }
 *
 * Leave events caused by an opening popup menu are ignored.
 *
 * containsCursor() tells where the pointer is when no event has been
 * received yet, for instance right after the window was shown.
 */
class LeaveEventFilter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject * target READ target WRITE setTarget NOTIFY targetChanged FINAL)

public:
    using QObject::QObject;
    ~LeaveEventFilter();

    QObject * target() const { return m_target; }
    void setTarget(QObject *target);

    Q_INVOKABLE bool containsCursor() const;

signals:
    void targetChanged();
    void exited();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;

private:
    QPointer<QObject> m_target;
};

#endif // LEAVEEVENTFILTER_HPP
