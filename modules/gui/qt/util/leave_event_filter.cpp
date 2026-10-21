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
#include <QEvent>

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

bool LeaveEventFilter::eventFilter(QObject *, QEvent *event)
{
    if (event->type() == QEvent::Leave && !QApplication::activePopupWidget())
        emit exited();

    return false;
}
