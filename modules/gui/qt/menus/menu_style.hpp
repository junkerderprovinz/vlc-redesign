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

#ifndef MENU_STYLE_HPP
#define MENU_STYLE_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QProxyStyle>

class MainCtx;
class SystemPalette;

/**
 * Draws every QMenu of the interface with the colors and metrics of the
 * interface palette: rounded translucent panel, tall rows with leading
 * icons and right aligned shortcuts, submenus beside their parent.
 */
class MenuStyle : public QProxyStyle
{
    Q_OBJECT

public:
    explicit MenuStyle(MainCtx *ctx, QObject *parent = nullptr);
    ~MenuStyle() override;

    void polish(QWidget *widget) override;
    void unpolish(QWidget *widget) override;
    using QProxyStyle::polish;
    using QProxyStyle::unpolish;

    int pixelMetric(PixelMetric metric, const QStyleOption *option = nullptr,
                    const QWidget *widget = nullptr) const override;
    int styleHint(StyleHint hint, const QStyleOption *option = nullptr,
                  const QWidget *widget = nullptr, QStyleHintReturn *returnData = nullptr) const override;
    QSize sizeFromContents(ContentsType type, const QStyleOption *option,
                           const QSize &size, const QWidget *widget) const override;
    void drawPrimitive(PrimitiveElement element, const QStyleOption *option,
                       QPainter *painter, const QWidget *widget = nullptr) const override;
    void drawControl(ControlElement element, const QStyleOption *option,
                     QPainter *painter, const QWidget *widget = nullptr) const override;

protected:
    bool eventFilter(QObject *object, QEvent *event) override;

private:
    void updatePalette();
    int dp(int px) const;

    MainCtx *m_ctx;
    SystemPalette *m_palette;
};

#endif // MENU_STYLE_HPP
