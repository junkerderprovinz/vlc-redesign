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

#include "menu_style.hpp"

#include "maininterface/mainctx.hpp"
#include "style/systempalette.hpp"
#include "util/color_scheme_model.hpp"
#include "util/colorizedsvgicon.hpp"

#include <QApplication>
#include <QEvent>
#include <QMenu>
#include <QPainter>
#include <QPainterPath>
#include <QRegularExpression>
#include <QStyleOptionMenuItem>

namespace {

constexpr int ROW_HEIGHT = 48;
constexpr int ROW_PADDING = 14;
constexpr int ROW_RADIUS = 6;
constexpr int PANEL_RADIUS = 10;
constexpr int PANEL_MARGIN = 4;
constexpr int PANEL_WIDTH = 265;
constexpr int ICON_SIZE = 24;
constexpr int SPACING = 10;
constexpr int SHORTCUT_SPACING = 24;
constexpr int SUBMENU_GAP = 11;

const QMenu *menuOf(const QWidget *widget)
{
    return qobject_cast<const QMenu *>(widget);
}

/* "Ctrl+Shift+O" is shown as "Ctrl + Shift + O" */
QString shortcutText(const QString &text)
{
    static const QRegularExpression separator(QStringLiteral("(?<=[^+\\s])\\+(?=\\S)"));
    QString spaced = text;
    return spaced.replace(separator, QStringLiteral(" + "));
}

/* @a path is drawn in a 24x24 box */
void strokeInBox(QPainter *painter, const QRect &box, const QPainterPath &path,
                 const QColor &color, qreal width)
{
    painter->save();
    painter->translate(box.topLeft());
    painter->scale(box.width() / 24.0, box.height() / 24.0);
    painter->setPen(QPen(color, width, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    painter->setBrush(Qt::NoBrush);
    painter->drawPath(path);
    painter->restore();
}

void drawCheck(QPainter *painter, const QRect &box, const QColor &color)
{
    QPainterPath path;
    path.moveTo(5.5, 12.5);
    path.lineTo(9.5, 16.5);
    path.lineTo(18.5, 7.5);
    strokeInBox(painter, box, path, color, 2.0);
}

void drawChevron(QPainter *painter, const QRect &box, const QColor &color)
{
    QPainterPath path;
    path.moveTo(10, 7);
    path.lineTo(15, 12);
    path.lineTo(10, 17);
    strokeInBox(painter, box, path, color, 1.5);
}

}

QIcon MenuStyle::icon(const QString &file, const QColor &text, const QColor &accent)
{
    /* single color icons have no color key, they inherit a fill set on the root element */
    static const QString root = QStringLiteral("xmlns=\"http://www.w3.org/2000/svg\">");
    return ColorizedSvgIcon(file, text, accent, {},
                            { { root, QStringLiteral("xmlns=\"http://www.w3.org/2000/svg\" fill=\"%1\">")
                                          .arg(text.name(QColor::HexRgb)) } });
}

MenuStyle::MenuStyle(MainCtx *ctx, QObject *parent)
    : QProxyStyle(QApplication::style()->name())
    , m_ctx(ctx)
    , m_palette(new SystemPalette(this))
{
    setParent(parent);

    ColorSchemeModel *scheme = m_ctx->getColorScheme();
    m_palette->setCtx(m_ctx);
    m_palette->setSource(scheme->currentScheme());
    connect(scheme, &ColorSchemeModel::currentChanged, this, [this, scheme]() {
        m_palette->setSource(scheme->currentScheme());
    });
    connect(m_palette, &SystemPalette::paletteChanged, this, &MenuStyle::updatePalette);
    connect(m_ctx, &MainCtx::intfScaleFactorChanged, this, &MenuStyle::updatePalette);
    updatePalette();

    qApp->installEventFilter(this);
}

MenuStyle::~MenuStyle()
{
    qApp->removeEventFilter(this);
    for (QWidget *widget : QApplication::allWidgets())
        if (widget->style() == this)
            widget->setStyle(nullptr);
}

bool MenuStyle::eventFilter(QObject *object, QEvent *event)
{
    if (event->type() == QEvent::Polish)
    {
        QMenu *menu = qobject_cast<QMenu *>(object);
        if (menu && menu->style() != this)
            menu->setStyle(this);
    }
    return QProxyStyle::eventFilter(object, event);
}

void MenuStyle::updatePalette()
{
    typedef ColorContext C;
    const auto color = [this](C::ColorSection section, C::ColorName name, C::ColorState state = C::Normal) {
        return m_palette->getColor(C::ComboBox, section, name, state);
    };

    /* a native menu has no backdrop blur, the glass color is drawn opaque */
    QColor panel = color(C::Bg, C::Neutral);
    panel.setAlphaF(1.0);

    QPalette palette = QApplication::palette();
    for (QPalette::ColorGroup group : { QPalette::Active, QPalette::Inactive, QPalette::Disabled })
    {
        const QColor text = color(C::Fg, C::Primary, group == QPalette::Disabled ? C::Disabled : C::Normal);
        palette.setColor(group, QPalette::Window, panel);
        palette.setColor(group, QPalette::Base, panel);
        palette.setColor(group, QPalette::Button, panel);
        palette.setColor(group, QPalette::WindowText, text);
        palette.setColor(group, QPalette::Text, text);
        palette.setColor(group, QPalette::ButtonText, text);
        palette.setColor(group, QPalette::Highlight, color(C::Bg, C::Highlight));
        palette.setColor(group, QPalette::HighlightedText, text);
        palette.setColor(group, QPalette::PlaceholderText, color(C::Fg, C::Secondary));
        palette.setColor(group, QPalette::Mid, color(C::Decoration, C::Separator));
    }
    QApplication::setPalette(palette, "QMenu");

    QFont font = QApplication::font();
    font.setPixelSize(dp(14));
    QApplication::setFont(font, "QMenu");
}

int MenuStyle::dp(int px) const
{
    return qRound(px * m_ctx->getIntfUserScaleFactor());
}

void MenuStyle::polish(QWidget *widget)
{
    if (QMenu *menu = qobject_cast<QMenu *>(widget))
    {
        menu->setAttribute(Qt::WA_TranslucentBackground);
        menu->setWindowFlag(Qt::FramelessWindowHint);
        menu->setWindowFlag(Qt::NoDropShadowWindowHint);
        return;
    }
    QProxyStyle::polish(widget);
}

void MenuStyle::unpolish(QWidget *widget)
{
    if (QMenu *menu = qobject_cast<QMenu *>(widget))
    {
        menu->setAttribute(Qt::WA_TranslucentBackground, false);
        return;
    }
    QProxyStyle::unpolish(widget);
}

int MenuStyle::pixelMetric(PixelMetric metric, const QStyleOption *option, const QWidget *widget) const
{
    if (!menuOf(widget))
        return QProxyStyle::pixelMetric(metric, option, widget);

    switch (metric)
    {
    case PM_MenuPanelWidth:
    case PM_MenuDesktopFrameWidth:
        return 0;
    case PM_MenuHMargin:
    case PM_MenuVMargin:
        return dp(PANEL_MARGIN);
    case PM_SubMenuOverlap:
        /* the submenu opens SUBMENU_GAP beside the panel */
        return dp(SUBMENU_GAP + PANEL_MARGIN);
    case PM_SmallIconSize:
        return dp(ICON_SIZE);
    default:
        return QProxyStyle::pixelMetric(metric, option, widget);
    }
}

int MenuStyle::styleHint(StyleHint hint, const QStyleOption *option, const QWidget *widget,
                         QStyleHintReturn *returnData) const
{
    if (menuOf(widget))
    {
        switch (hint)
        {
        case SH_UnderlineShortcut:
        case SH_Menu_FlashTriggeredItem:
        case SH_Menu_FadeOutOnHide:
            return 0;
        case SH_Menu_SubMenuPopupDelay:
            return 140;
        default:
            break;
        }
    }
    return QProxyStyle::styleHint(hint, option, widget, returnData);
}

QSize MenuStyle::sizeFromContents(ContentsType type, const QStyleOption *option,
                                  const QSize &size, const QWidget *widget) const
{
    const auto item = qstyleoption_cast<const QStyleOptionMenuItem *>(option);
    if (type != CT_MenuItem || !item || !menuOf(widget))
        return QProxyStyle::sizeFromContents(type, option, size, widget);

    if (item->menuItemType == QStyleOptionMenuItem::Separator)
        return QSize(size.width(), dp(1));

    const bool iconColumn = item->maxIconWidth > 0;
    int width = 2 * dp(ROW_PADDING) + size.width();
    if (iconColumn)
        width += dp(ICON_SIZE) + dp(SPACING);

    const qsizetype tab = item->text.indexOf(QLatin1Char('\t'));
    if (tab >= 0)
    {
        const QString shortcut = item->text.mid(tab + 1);
        const QFontMetrics metrics(item->font);
        width += dp(SHORTCUT_SPACING)
               + metrics.horizontalAdvance(shortcutText(shortcut)) - metrics.horizontalAdvance(shortcut);
    }
    if (item->menuItemType == QStyleOptionMenuItem::SubMenu)
        width += dp(SPACING) + dp(ICON_SIZE);
    if (item->checkType != QStyleOptionMenuItem::NotCheckable && (!item->icon.isNull() || !iconColumn))
        width += dp(SPACING) + dp(ICON_SIZE);

    return QSize(std::max(width, dp(PANEL_WIDTH) - 2 * dp(PANEL_MARGIN)), dp(ROW_HEIGHT));
}

void MenuStyle::drawPrimitive(PrimitiveElement element, const QStyleOption *option,
                              QPainter *painter, const QWidget *widget) const
{
    if (!menuOf(widget))
        return QProxyStyle::drawPrimitive(element, option, painter, widget);

    switch (element)
    {
    case PE_PanelMenu:
        painter->save();
        painter->setRenderHint(QPainter::Antialiasing);
        painter->setPen(Qt::NoPen);
        painter->setBrush(option->palette.window());
        painter->drawRoundedRect(QRectF(option->rect), dp(PANEL_RADIUS), dp(PANEL_RADIUS));
        painter->restore();
        return;
    case PE_FrameMenu:
        return;
    default:
        return QProxyStyle::drawPrimitive(element, option, painter, widget);
    }
}

void MenuStyle::drawControl(ControlElement element, const QStyleOption *option,
                            QPainter *painter, const QWidget *widget) const
{
    if (!menuOf(widget))
        return QProxyStyle::drawControl(element, option, painter, widget);

    if (element == CE_MenuEmptyArea)
        return;

    const auto item = qstyleoption_cast<const QStyleOptionMenuItem *>(option);
    if (element != CE_MenuItem || !item)
        return QProxyStyle::drawControl(element, option, painter, widget);

    const QRect rect = item->rect;
    if (item->menuItemType == QStyleOptionMenuItem::Separator)
    {
        painter->fillRect(QRect(rect.left(), rect.top(), rect.width(), dp(1)), item->palette.mid());
        return;
    }

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);

    const bool enabled = item->state & State_Enabled;
    const QPalette::ColorGroup group = enabled ? QPalette::Normal : QPalette::Disabled;
    const QColor textColor = item->palette.color(group, QPalette::Text);
    const QColor hintColor = item->palette.color(group, QPalette::PlaceholderText);
    const QColor accent = enabled ? m_ctx->accentColor() : textColor;

    if (enabled && (item->state & State_Selected))
    {
        painter->setPen(Qt::NoPen);
        painter->setBrush(item->palette.highlight());
        painter->drawRoundedRect(QRectF(rect), dp(ROW_RADIUS), dp(ROW_RADIUS));
    }

    const int iconSize = dp(ICON_SIZE);
    const int iconTop = rect.top() + (rect.height() - iconSize) / 2;
    const bool checkable = item->checkType != QStyleOptionMenuItem::NotCheckable;
    /* the check mark takes the icon column, or the trailing edge when the menu has no icons */
    const bool iconColumn = item->maxIconWidth > 0;
    int left = rect.left() + dp(ROW_PADDING);
    int right = rect.right() + 1 - dp(ROW_PADDING);

    if (iconColumn)
    {
        const QRect slot(left, iconTop, iconSize, iconSize);
        if (!item->icon.isNull())
        {
            const QPixmap pixmap = item->icon.pixmap(slot.size(), widget->devicePixelRatioF(),
                                                     enabled ? QIcon::Normal : QIcon::Disabled);
            painter->drawPixmap(slot, pixmap);
        }
        else if (checkable && item->checked)
            drawCheck(painter, slot, accent);
        left += iconSize + dp(SPACING);
    }

    if (item->menuItemType == QStyleOptionMenuItem::SubMenu)
    {
        drawChevron(painter, QRect(right - iconSize, iconTop, iconSize, iconSize), textColor);
        right -= iconSize + dp(SPACING);
    }
    else if (checkable && item->checked && (!item->icon.isNull() || !iconColumn))
    {
        drawCheck(painter, QRect(right - iconSize, iconTop, iconSize, iconSize), accent);
        right -= iconSize + dp(SPACING);
    }

    painter->setFont(item->font);
    const qsizetype tab = item->text.indexOf(QLatin1Char('\t'));
    const QString label = tab >= 0 ? item->text.left(tab) : item->text;

    if (tab >= 0)
    {
        const QString shortcut = shortcutText(item->text.mid(tab + 1));
        painter->setPen(hintColor);
        painter->drawText(QRect(left, rect.top(), right - left, rect.height()),
                          Qt::AlignRight | Qt::AlignVCenter | Qt::TextSingleLine, shortcut);
        right -= painter->fontMetrics().horizontalAdvance(shortcut) + dp(SHORTCUT_SPACING);
    }

    int textFlags = Qt::AlignLeft | Qt::AlignVCenter | Qt::TextSingleLine | Qt::TextShowMnemonic;
    if (!styleHint(SH_UnderlineShortcut, item, widget))
        textFlags |= Qt::TextHideMnemonic;
    painter->setPen(textColor);
    painter->drawText(QRect(left, rect.top(), right - left, rect.height()), textFlags, label);

    painter->restore();
}
