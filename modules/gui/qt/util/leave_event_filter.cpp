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
#include "leave_event_filter.hpp"

#include <QApplication>
#include <QCursor>
#include <QEvent>
#include <QWindow>

#ifdef _WIN32
#include <windows.h>
#endif

LeaveEventFilter::~LeaveEventFilter()
{
    if (m_target)
        m_target->removeEventFilter(this);
}

void LeaveEventFilter::setTarget(QObject *target)
{
    if (m_target == target)
        return;

    if (m_target)
        m_target->removeEventFilter(this);

    m_target = target;

    if (m_target)
        m_target->installEventFilter(this);

    emit targetChanged();
}

bool LeaveEventFilter::containsCursor() const
{
    const auto window = qobject_cast<QWindow *>(m_target.data());
    if (!window)
        return false;

    return window->geometry().contains(QCursor::pos(window->screen()));
}

#ifdef _WIN32
// With client-side decoration, the window buttons answer the hit test as
// caption buttons so that Windows offers its snap layouts. Moving onto them
// leaves the client area, but not the window.
static bool isOverCaptionButton(QObject *target)
{
    const auto window = qobject_cast<QWindow *>(target);
    POINT point;
    if (!window || !GetCursorPos(&point))
        return false;

    const LRESULT hit = SendMessage(reinterpret_cast<HWND>(window->winId()), WM_NCHITTEST,
                                    0, MAKELPARAM(point.x, point.y));
    return hit == HTMINBUTTON || hit == HTMAXBUTTON || hit == HTCLOSE;
}
#endif

bool LeaveEventFilter::eventFilter(QObject *obj, QEvent *event)
{
    if (event->type() != QEvent::Leave || QApplication::activePopupWidget())
        return false;

#ifdef _WIN32
    if (isOverCaptionButton(obj))
        return false;
#endif

    emit exited();
    return false;
}
