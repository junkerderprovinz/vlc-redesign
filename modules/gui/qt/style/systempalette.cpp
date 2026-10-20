/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
#include "systempalette.hpp"
#include <QGuiApplication>
#include <QPalette>
#include <QSettings>
#include <QFile>
#include <maininterface/mainctx.hpp>
#include <vlc_modules.h>
#include <vlc_picture.h>

#include <algorithm>
#include <cmath>

namespace {

QColor setColorAlpha(const QColor& c1, float alpha)
{
    QColor c(c1);
    c.setAlphaF(alpha);
    return c;
}

#ifndef _WIN32
/**
 * function taken from QtBase gui/platform/unix/qgenericunixservices.cpp
 */
static inline QByteArray detectLinuxDesktopEnvironment()
{
    const QByteArray xdgCurrentDesktop = qgetenv("XDG_CURRENT_DESKTOP");
    if (!xdgCurrentDesktop.isEmpty())
        return xdgCurrentDesktop.toUpper(); // KDE, GNOME, UNITY, LXDE, MATE, XFCE...

    // Classic fallbacks
    if (!qEnvironmentVariableIsEmpty("KDE_FULL_SESSION"))
        return QByteArrayLiteral("KDE");
    if (!qEnvironmentVariableIsEmpty("GNOME_DESKTOP_SESSION_ID"))
        return QByteArrayLiteral("GNOME");

    // Fallback to checking $DESKTOP_SESSION (unreliable)
    QByteArray desktopSession = qgetenv("DESKTOP_SESSION");

    // This can be a path in /usr/share/xsessions
    int slash = desktopSession.lastIndexOf('/');
    if (slash != -1) {
        QSettings desktopFile(QFile::decodeName(desktopSession + ".desktop"), QSettings::IniFormat);
        desktopFile.beginGroup(QStringLiteral("Desktop Entry"));
        QByteArray desktopName = desktopFile.value(QStringLiteral("DesktopNames")).toByteArray();
        if (!desktopName.isEmpty())
            return desktopName;

        // try decoding just the basename
        desktopSession = desktopSession.mid(slash + 1);
    }

    if (desktopSession == "gnome")
        return QByteArrayLiteral("GNOME");
    else if (desktopSession == "xfce")
        return QByteArrayLiteral("XFCE");
    else if (desktopSession == "kde")
        return QByteArrayLiteral("KDE");

    return QByteArrayLiteral("UNKNOWN");
}

bool isGTKBasedEnvironment()
{
    QList<QByteArray> gtkBasedEnvironments{
        "GNOME",
        "X-CINNAMON",
        "UNITY",
        "MATE",
        "XFCE",
        "LXDE"
    };
    const QList<QByteArray> desktopNames = detectLinuxDesktopEnvironment().split(':');
    for (const QByteArray& desktopName: desktopNames)
    {
        if (gtkBasedEnvironments.contains(desktopName))
            return true;
    }
    return false;
}
#endif


static void PaletteChangedCallback(vlc_qt_theme_provider_t*, void* data)
{
    auto priv = static_cast<ExternalPaletteImpl*>(data);
    emit priv->paletteChanged();
}

static void MetricsChangedCallback(vlc_qt_theme_provider_t*, vlc_qt_theme_image_type type, void* data)
{
    auto priv = static_cast<ExternalPaletteImpl*>(data);
    assert(priv);
    priv->updateMetrics(type);
}


static void ReleaseVLCPictureCb(void* data)
{
    auto pic = static_cast<picture_t*>(data);
    if (pic)
        picture_Release(pic);
}


static void setColorRBGAInt(
    vlc_qt_theme_provider_t* obj,
    vlc_qt_theme_color_set set, vlc_qt_theme_color_section section,
    vlc_qt_theme_color_name name, vlc_qt_theme_color_state state,
    int r, int g, int b, int a)
{
    auto palette = static_cast<SystemPalette*>(obj->setColorData);
    QColor color(r,g,b,a);
    palette->setColor(
        static_cast<ColorContext::ColorSet>(set), static_cast<ColorContext::ColorSection>(section),
        static_cast<ColorContext::ColorName>(name), static_cast<ColorContext::ColorState>(state),
        color);
}

static void setColorRBGAFloat(
    vlc_qt_theme_provider_t* obj,
    vlc_qt_theme_color_set set, vlc_qt_theme_color_section section,
    vlc_qt_theme_color_name name, vlc_qt_theme_color_state state,
    double r, double g, double b, double a)
{
    auto palette = static_cast<SystemPalette*>(obj->setColorData);
    QColor color;
    color.setRgbF(r,g,b,a);
    palette->setColor(
        static_cast<ColorContext::ColorSet>(set), static_cast<ColorContext::ColorSection>(section),
        static_cast<ColorContext::ColorName>(name), static_cast<ColorContext::ColorState>(state),
        color);
}

}

//ExternalPaletteImpl

ExternalPaletteImpl::ExternalPaletteImpl(MainCtx* ctx, SystemPalette& palette, QObject* parent)
    : QObject(parent)
    , m_palette(palette)
    , m_ctx(ctx)
{
}

ExternalPaletteImpl::~ExternalPaletteImpl()
{
    if (m_provider)
    {
        if (m_provider->close)
            m_provider->close(m_provider);
        if (m_module)
            module_unneed(m_provider, m_module);
        vlc_object_delete(m_provider);
    }
}

bool ExternalPaletteImpl::init()
{
    QString preferedProvider;
#ifndef _WIN32
    if (isGTKBasedEnvironment())
        preferedProvider = "qt-themeprovider-gtk";
#endif

    m_provider = vlc_object_create<vlc_qt_theme_provider_t>(m_ctx->getIntf());
    if (!m_provider)
        return false;


    m_provider->paletteUpdated = PaletteChangedCallback;
    m_provider->paletteUpdatedData = this;

    m_provider->metricsUpdated = MetricsChangedCallback;
    m_provider->metricsUpdatedData = this;

    m_provider->setColorF = setColorRBGAFloat;
    m_provider->setColorInt = setColorRBGAInt;
    m_provider->setColorData = &m_palette;

    m_module = module_need(m_provider, "qt theme provider",
                           preferedProvider.isNull() ? nullptr : qtu(preferedProvider),
                           true);
    if (!m_module)
        return false;
    return true;
}

bool ExternalPaletteImpl::isThemeDark() const
{
    if (!m_provider->isThemeDark)
        return false;
    return m_provider->isThemeDark(m_provider);
}

bool ExternalPaletteImpl::hasCSDImages() const
{
    if (!m_provider->supportThemeImage)
        return false;
    return m_provider->supportThemeImage(m_provider, VLC_QT_THEME_IMAGE_TYPE_CSD_BUTTON);
}


QImage ExternalPaletteImpl::getCSDImage(vlc_qt_theme_csd_button_type type, vlc_qt_theme_csd_button_state state, bool maximized, bool active, int bannerHeight)
{
    if (!m_provider->getThemeImage)
        return {};
    vlc_qt_theme_image_setting imageSettings;
    imageSettings.windowScaleFactor = m_ctx->intfMainWindow()->devicePixelRatio();
    imageSettings.userScaleFacor = m_ctx->getIntfUserScaleFactor();
    imageSettings.u.csdButton.buttonType = type;
    imageSettings.u.csdButton.state = state;
    imageSettings.u.csdButton.maximized = maximized;
    imageSettings.u.csdButton.active = active;
    imageSettings.u.csdButton.bannerHeight = bannerHeight;
    picture_t* pic = m_provider->getThemeImage(m_provider, VLC_QT_THEME_IMAGE_TYPE_CSD_BUTTON, &imageSettings);
    if (!pic)
        return {};

    QImage::Format format = QImage::Format_Invalid;
    switch (pic->format.i_chroma)
    {
    case VLC_CODEC_ARGB:
        format = QImage::Format_ARGB32_Premultiplied;
        break;
    case VLC_CODEC_RGBA:
        format = QImage::Format_RGBA8888_Premultiplied;
        break;
    case VLC_CODEC_RGB24:
        format = QImage::Format_RGB888;
        break;
    default:
        msg_Err(m_ctx->getIntf(), "unexpected image format from theme provider");
        break;
    }

    return QImage(pic->p[0].p_pixels,
            pic->format.i_visible_width, pic->format.i_visible_height, pic->p[0].i_pitch,
            format,
            ReleaseVLCPictureCb, pic
            );
}

CSDMetrics* ExternalPaletteImpl::getCSDMetrics() const
{
    return m_csdMetrics.get();
}

int ExternalPaletteImpl::update()
{
    if (m_provider->updatePalette)
        return m_provider->updatePalette(m_provider);
    return VLC_EGENERIC;
}

void ExternalPaletteImpl::updateMetrics(vlc_qt_theme_image_type type)
{
    if (m_provider->getThemeMetrics)
    {
        if (type == VLC_QT_THEME_IMAGE_TYPE_CSD_BUTTON)
        {
            m_csdMetrics.reset();
            [&](){
                if (!m_provider->getThemeMetrics)
                    return;
                vlc_qt_theme_metrics metrics;
                memset(&metrics, 0, sizeof(metrics));
                bool ret = m_provider->getThemeMetrics(m_provider, VLC_QT_THEME_IMAGE_TYPE_CSD_BUTTON, &metrics);
                if (!ret)
                    return;
                m_csdMetrics = std::make_unique<CSDMetrics>();
                m_csdMetrics->interNavButtonSpacing = metrics.u.csd.interNavButtonSpacing;

                m_csdMetrics->csdFrameMarginLeft = metrics.u.csd.csdFrameMarginLeft;
                m_csdMetrics->csdFrameMarginRight = metrics.u.csd.csdFrameMarginRight;
                m_csdMetrics->csdFrameMarginTop = metrics.u.csd.csdFrameMarginTop;
                m_csdMetrics->csdFrameMarginBottom = metrics.u.csd.csdFrameMarginBottom;
            }();
            emit CSDMetricsChanged();
        }
    }
}

SystemPalette::SystemPalette(QObject* parent)
    : QObject(parent)
{

}

void SystemPalette::componentComplete()
{
    updatePalette();
}

ColorSchemeModel::ColorScheme SystemPalette::source() const
{
    return m_source;
}

QImage SystemPalette::getCSDImage(vlc_qt_theme_csd_button_type type, vlc_qt_theme_csd_button_state state, bool maximized, bool active, int bannerHeight)
{
    if (!hasCSDImage())
        return QImage();
    assert(m_palettePriv);
    return m_palettePriv->getCSDImage(type, state, maximized, active, bannerHeight);

}

CSDMetrics* SystemPalette::getCSDMetrics() const
{
    if (!m_palettePriv)
        return nullptr;
    return m_palettePriv->getCSDMetrics();
}

bool SystemPalette::hasCSDImage() const
{
    if (!m_palettePriv)
        return false;
    return m_palettePriv->hasCSDImages();
}

void SystemPalette::setSource(ColorSchemeModel::ColorScheme source)
{
    if (m_source == source)
        return;
    m_source = source;

    updatePalette();
    emit sourceChanged();
}

void SystemPalette::setCtx(MainCtx* ctx)
{
    if (ctx == m_ctx)
        return;
    if (m_ctx)
        disconnect(m_ctx, &MainCtx::accentColorChanged, this, &SystemPalette::updatePalette);
    m_ctx = ctx;
    if (m_ctx)
        connect(m_ctx, &MainCtx::accentColorChanged, this, &SystemPalette::updatePalette);
    emit ctxChanged();
    updatePalette();
}

void SystemPalette::updatePalette()
{
    m_palettePriv.reset();
    switch(m_source)
    {
    case ColorSchemeModel::System:
        makeSystemPalette();
        break;
    case ColorSchemeModel::Day:
        makeLightPalette();
        break;
    case ColorSchemeModel::Night:
        makeDarkPalette();
        break;
    default:
        break;
    }

    if (m_palettePriv)
    {
        connect(
            m_palettePriv.get(), &ExternalPaletteImpl::paletteChanged,
            this, &SystemPalette::updatePalette);
        connect(
            m_palettePriv.get(), &ExternalPaletteImpl::CSDMetricsChanged,
            this, &SystemPalette::CSDMetricsChanged);
    }
    emit paletteChanged();

    bool hasCSDImage = m_palettePriv && m_palettePriv->hasCSDImages();
    if (m_hasCSDImage != hasCSDImage)
    {
        m_hasCSDImage = hasCSDImage;
        emit hasCSDImageChanged();
    }
}

static quint64 makeKey(ColorContext::ColorSet colorSet, ColorContext::ColorSection section,
                       ColorContext::ColorName name, ColorContext::ColorState state)
{
    static_assert(VQTC_STATE_COUNT < (1<<4), "");
    static_assert(VQTC_SECTION_COUNT < (1<<4), "");
    static_assert(VQTC_NAME_COUNT < (1<<8), "");
    static_assert(VQTC_SET_COUNT < (1<<16), "");
    return  (colorSet << 16)
        + (name << 8)
        + (section << 4)
        + state;
}

void SystemPalette::setColor(ColorContext::ColorSet colorSet,  ColorContext::ColorSection section,
                             ColorContext::ColorName name, ColorContext::ColorState state, QColor color)
{

    quint64 key = makeKey(colorSet, section, name, state);
    m_colorMap[key] = color;
}


QColor SystemPalette::getColor(ColorContext::ColorSet colorSet, ColorContext::ColorSection section,
                               ColorContext::ColorName name, ColorContext::ColorState state) const
{
    typedef ColorContext C;

    quint64 key = makeKey(colorSet, section, name, state);
    auto it = m_colorMap.find(key);
    if (it != m_colorMap.cend())
        return *it;
    //we don't have the role explicitly set, fallback to the normal state
    key = makeKey(colorSet, section, name, C::Normal);
    it = m_colorMap.find(key);
    if (it != m_colorMap.cend())
        return *it;
    //we don't have the role explicitly set, fallback to the colorSet View
    //TODO do we want finer hierarchy?
    if (colorSet != C::View)
    {
        return getColor(C::View, section, name, state);
    }
    else
    {
        //nothing matches, that's probably an issue, return an ugly color
        return Qt::magenta;
    }
}


namespace {

float srgbToLinear(float c)
{
    return (c <= 0.04045f) ? c / 12.92f : std::pow((c + 0.055f) / 1.055f, 2.4f);
}

float linearToSrgb(float c)
{
    c = std::clamp(c, 0.f, 1.f);
    return (c <= 0.0031308f) ? c * 12.92f : 1.055f * std::pow(c, 1.f / 2.4f) - 0.055f;
}

/**
 * mix two colors in the sRGB space, @a amount is the weight of @a c1
 */
QColor mixColor(const QColor& c1, const QColor& c2, float amount)
{
    const auto lerp = [amount](float a, float b) { return a * amount + b * (1.f - amount); };
    return QColor::fromRgbF(
        lerp(c1.redF(), c2.redF()),
        lerp(c1.greenF(), c2.greenF()),
        lerp(c1.blueF(), c2.blueF()),
        lerp(c1.alphaF(), c2.alphaF()));
}

/**
 * shift the perceived lightness of a color, chroma and hue are preserved (OKLCH)
 */
QColor shiftLightness(const QColor& color, float delta)
{
    const float r = srgbToLinear(color.redF());
    const float g = srgbToLinear(color.greenF());
    const float b = srgbToLinear(color.blueF());

    const float l = std::cbrt(0.4122214708f * r + 0.5363325363f * g + 0.0514459929f * b);
    const float m = std::cbrt(0.2119034982f * r + 0.6806995451f * g + 0.1073969566f * b);
    const float s = std::cbrt(0.0883024619f * r + 0.2817188376f * g + 0.6299787005f * b);

    const float labL = 0.2104542553f * l + 0.7936177850f * m - 0.0040720468f * s + delta;
    const float labA = 1.9779984951f * l - 2.4285922050f * m + 0.4505937099f * s;
    const float labB = 0.0259040371f * l + 0.7827717662f * m - 0.8086757660f * s;

    const float l2 = std::pow(labL + 0.3963377774f * labA + 0.2158037573f * labB, 3.f);
    const float m2 = std::pow(labL - 0.1055613458f * labA - 0.0638541728f * labB, 3.f);
    const float s2 = std::pow(labL - 0.0894841775f * labA - 1.2914855480f * labB, 3.f);

    return QColor::fromRgbF(
        linearToSrgb( 4.0767416621f * l2 - 3.3077115913f * m2 + 0.2309699292f * s2),
        linearToSrgb(-1.2684380046f * l2 + 2.6097574011f * m2 - 0.3413193965f * s2),
        linearToSrgb(-0.0041960863f * l2 - 0.7034186147f * m2 + 1.7076147010f * s2),
        color.alphaF());
}

float relativeLuminance(const QColor& c)
{
    return 0.2126f * srgbToLinear(c.redF())
         + 0.7152f * srgbToLinear(c.greenF())
         + 0.0722f * srgbToLinear(c.blueF());
}

/**
 * text color for content drawn on @a background, @a dark unless @a light
 * gives a better contrast ratio
 */
QColor textOnColor(const QColor& background, const QColor& dark, const QColor& light)
{
    const float lb = relativeLuminance(background);
    const float darkRatio = (lb + 0.05f) / (relativeLuminance(dark) + 0.05f);
    const float lightRatio = (relativeLuminance(light) + 0.05f) / (lb + 0.05f);
    return (darkRatio >= lightRatio) ? dark : light;
}

void setControlColors(SystemPalette& palette, const DesignTokens& t)
{
    typedef ColorContext C;

    // every state, so that the values of the base palette do not show through
    const auto setColorAll = [&palette](C::ColorSet set, C::ColorSection section, C::ColorName name,
                                        const QColor& color) {
        for (C::ColorState state : { C::Normal, C::Disabled, C::Pressed, C::Hovered, C::Focused })
            palette.setColor(set, section, name, state, color);
    };

    //Standard Buttons, secondary is the cancel button of dialogs
    {
        C::ColorSet CS = C::ButtonStandard;
        setColorAll(CS, C::Bg, C::Primary, t.bgB2);
        palette.setColor(CS, C::Bg, C::Primary, C::Hovered, t.bgA4);
        palette.setColor(CS, C::Bg, C::Primary, C::Focused, t.bgA4);
        palette.setColor(CS, C::Bg, C::Primary, C::Pressed, t.bgA3);

        setColorAll(CS, C::Bg, C::Secondary, t.bgA3);
        palette.setColor(CS, C::Bg, C::Secondary, C::Hovered, t.bgA1);
        palette.setColor(CS, C::Bg, C::Secondary, C::Focused, t.bgA1);
        palette.setColor(CS, C::Bg, C::Secondary, C::Pressed, t.bgA2);

        setColorAll(CS, C::Fg, C::Primary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA3);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);

        setColorAll(CS, C::Fg, C::Secondary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Secondary, C::Disabled, t.fgDisabled);

        setColorAll(CS, C::Decoration, C::Border, Qt::transparent);
        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //Accent Buttons, secondary is the primary button of dialogs
    {
        C::ColorSet CS = C::ButtonAccent;
        setColorAll(CS, C::Bg, C::Primary, t.accentBright);
        palette.setColor(CS, C::Bg, C::Primary, C::Normal, t.accent);
        palette.setColor(CS, C::Bg, C::Primary, C::Pressed, t.accentDim);
        palette.setColor(CS, C::Bg, C::Primary, C::Disabled, t.bgAccentBright);

        setColorAll(CS, C::Fg, C::Primary, t.fgOnAccent);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.accent);

        setColorAll(CS, C::Bg, C::Secondary, mixColor(t.accent, t.bgAccentBright, 0.14f));
        palette.setColor(CS, C::Bg, C::Secondary, C::Normal, t.bgAccentBright);
        palette.setColor(CS, C::Bg, C::Secondary, C::Disabled, setColorAlpha(t.bgAccentBright, 0.5));

        setColorAll(CS, C::Fg, C::Secondary, t.accent);
        palette.setColor(CS, C::Fg, C::Secondary, C::Disabled, setColorAlpha(t.accent, 0.5));

        setColorAll(CS, C::Decoration, C::Border, Qt::transparent);
        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //tool button
    {
        C::ColorSet CS = C::ToolButton;
        setColorAll(CS, C::Bg, C::Primary, t.hover);
        palette.setColor(CS, C::Bg, C::Primary, C::Normal, Qt::transparent);
        palette.setColor(CS, C::Bg, C::Primary, C::Disabled, Qt::transparent);
        setColorAll(CS, C::Bg, C::Secondary, t.bgB2);

        setColorAll(CS, C::Fg, C::Primary, t.fg2);
        palette.setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
        setColorAll(CS, C::Fg, C::Secondary, t.fg2);

        setColorAll(CS, C::Decoration, C::Border, Qt::transparent);
        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //tab button
    {
        C::ColorSet CS = C::TabButton;
        setColorAll(CS, C::Bg, C::Primary, t.hover);
        palette.setColor(CS, C::Bg, C::Primary, C::Normal, Qt::transparent);
        palette.setColor(CS, C::Bg, C::Primary, C::Disabled, Qt::transparent);

        setColorAll(CS, C::Fg, C::Primary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA3);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
        setColorAll(CS, C::Fg, C::Secondary, t.fgA2);

        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //tooltip
    {
        C::ColorSet CS = C::Tooltip;
        setColorAll(CS, C::Bg, C::Primary, t.bgA1);
        setColorAll(CS, C::Fg, C::Primary, t.fg2);
        setColorAll(CS, C::Decoration, C::Border, t.dividerDim);
    }

    //slider, the border is the thumb of scroll bars
    {
        C::ColorSet CS = C::Slider;
        setColorAll(CS, C::Bg, C::Primary, t.bgB2);
        setColorAll(CS, C::Bg, C::Secondary, t.bgAccentBright);
        setColorAll(CS, C::Fg, C::Primary, t.accent);
        setColorAll(CS, C::Fg, C::Secondary, t.accentDim);
        setColorAll(CS, C::Decoration, C::Indicator, t.bgAccentDark);

        setColorAll(CS, C::Decoration, C::Border, t.fgA3);
        palette.setColor(CS, C::Decoration, C::Border, C::Normal, t.dividerBright);
    }

    //popups: combo boxes, menus and dialogs
    {
        C::ColorSet CS = C::ComboBox;
        setColorAll(CS, C::Bg, C::Primary, t.bgB2);

        setColorAll(CS, C::Bg, C::Secondary, t.bgA2);
        palette.setColor(CS, C::Bg, C::Secondary, C::Normal, t.bgA4);
        palette.setColor(CS, C::Bg, C::Secondary, C::Disabled, t.bgA4);

        setColorAll(CS, C::Bg, C::Highlight, t.bgA2);
        setColorAll(CS, C::Bg, C::Neutral, t.bgA3Glass);

        setColorAll(CS, C::Fg, C::Primary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
        setColorAll(CS, C::Fg, C::Secondary, t.fgA3);
        setColorAll(CS, C::Fg, C::Highlight, t.fg1);

        setColorAll(CS, C::Decoration, C::Border, Qt::transparent);
        setColorAll(CS, C::Decoration, C::Separator, t.dividerDim);
        setColorAll(CS, C::Decoration, C::Shadow, t.shadow);
        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //TextField and SpinBox, the secondary background is the search field
    for (C::ColorSet CS : { C::TextField, C::SpinBox })
    {
        setColorAll(CS, C::Bg, C::Primary, t.bgB2);
        setColorAll(CS, C::Bg, C::Secondary, t.isDark ? t.bgA5 : t.bgA2);

        setColorAll(CS, C::Fg, C::Primary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
        setColorAll(CS, C::Fg, C::Secondary, t.fgA4);

        setColorAll(CS, C::Bg, C::Highlight, t.bgAccentBright);
        setColorAll(CS, C::Fg, C::Highlight, t.accent);

        setColorAll(CS, C::Decoration, C::Border, t.bgA4);
        palette.setColor(CS, C::Decoration, C::Border, C::Hovered, t.bgA2);
        palette.setColor(CS, C::Decoration, C::Border, C::Focused, t.accentDim);

        setColorAll(CS, C::Decoration, C::Indicator, t.fgA3);
        setColorAll(CS, C::Decoration, C::Accent, t.accent);
    }

    //SpinBox arrows
    {
        C::ColorSet CS = C::SpinBox;
        setColorAll(CS, C::Fg, C::Secondary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Secondary, C::Normal, t.fgA3);
        palette.setColor(CS, C::Fg, C::Secondary, C::Disabled, t.fgDisabled);
    }

    //Switch, also used by segmented controls
    {
        C::ColorSet CS = C::Switch;
        setColorAll(CS, C::Bg, C::Primary, t.bgB2);
        setColorAll(CS, C::Bg, C::Secondary, t.bgAccentBright);
        setColorAll(CS, C::Bg, C::Highlight, t.bgA4);

        setColorAll(CS, C::Fg, C::Primary, t.fgA2);
        palette.setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA3);
        palette.setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
        setColorAll(CS, C::Fg, C::Secondary, t.accent);
        setColorAll(CS, C::Fg, C::Highlight, t.fgA3);

        setColorAll(CS, C::Decoration, C::Accent, t.accentDim);
        setColorAll(CS, C::Decoration, C::Indicator, t.fgA4);
        setColorAll(CS, C::Decoration, C::Border, Qt::transparent);
    }
}

}

DesignTokens DesignTokens::dark(const QColor& accent)
{
    DesignTokens t;

    t.fg1 = QColor("#eaeaea");
    t.fg2 = QColor("#c6c6c6");
    t.fgA1 = QColor("#969696");
    t.fgA2 = QColor("#8f8f8f");
    t.fgA3 = QColor("#6b6b6b");
    t.fgA4 = QColor("#404040");
    t.fgB1 = QColor("#161616");

    t.bgA1 = QColor("#222222");
    t.bgA2 = QColor("#1f1f1f");
    t.bgA3 = QColor("#1b1b1b");
    t.bgA4 = QColor("#191919");
    t.bgA5 = QColor("#151515");
    t.bgB1 = QColor("#0e0e0e");
    t.bgB2 = QColor("#090909");
    t.bgA3Glass = setColorAlpha(QColor("#191919"), 0.95);
    t.bgB1Glass = setColorAlpha(QColor("#0e0e0e"), 0.95);
    t.bgB2Glass = setColorAlpha(Qt::black, 0.8);

    t.dividerBright = QColor("#373737");
    t.dividerDim = QColor("#222222");

    t.accent = accent;
    t.accentBright = shiftLightness(accent, 0.1f);
    t.accentDim = mixColor(accent, Qt::black, 0.81f);
    t.bgAccentBright = mixColor(accent, Qt::black, 0.26f);
    t.bgAccentDark = mixColor(accent, QColor("#111111"), 0.047f);
    t.accentLogo = QColor("#d37918");
    t.fgOnAccent = textOnColor(accent, t.fgB1, t.fg1);

    t.positive = QColor("#8fb31b");
    t.neutral = QColor("#c49e23");
    t.negative = QColor("#e15032");

    t.shadow = setColorAlpha(Qt::black, 0.46);

    t.fgDisabled = t.fgA4;
    t.hover = setColorAlpha(Qt::white, 0.06);

    t.isDark = true;

    return t;
}

DesignTokens DesignTokens::light(const QColor& accent)
{
    DesignTokens t;

    t.fg1 = QColor("#161616");
    t.fg2 = QColor("#2e2e2e");
    t.fgA1 = QColor("#3c3c3c");
    t.fgA2 = QColor("#2e2e2e");
    t.fgA3 = QColor("#6b6b6b");
    t.fgA4 = QColor("#3b3b3b");
    t.fgB1 = QColor("#161616");

    t.bgA1 = QColor("#ededed");
    t.bgA2 = QColor("#dddddd");
    t.bgA3 = QColor("#d5d5d5");
    t.bgA4 = QColor("#b3b3b3");
    t.bgA5 = QColor("#888888");
    t.bgB1 = QColor("#e7e7e7");
    t.bgB2 = QColor("#dedede");
    t.bgA3Glass = setColorAlpha(QColor("#d5d5d5"), 0.75);
    t.bgB1Glass = setColorAlpha(QColor("#e7e7e7"), 0.8);
    t.bgB2Glass = setColorAlpha(QColor("#dedede"), 0.8);

    t.dividerBright = QColor("#9b9b9b");
    t.dividerDim = QColor("#acacac");

    // the day accent is the night one with a brighter value, #d37918 gives #e8851a
    const QColor base = accent.lighter(110);
    t.accent = base;
    t.accentBright = shiftLightness(base, 0.08f);
    t.accentDim = mixColor(base, Qt::black, 0.65f);
    t.bgAccentBright = mixColor(base, QColor("#d1d1d1"), 0.30f);
    t.bgAccentDark = mixColor(base, QColor("#b8b8b8"), 0.30f);
    t.accentLogo = QColor("#c2711a");
    t.fgOnAccent = textOnColor(base, t.fgB1, QColor("#eaeaea"));

    t.positive = QColor("#5f8010");
    t.neutral = QColor("#94760f");
    t.negative = QColor("#c23a1d");

    t.shadow = setColorAlpha(Qt::black, 0.18);

    // fgA4 is nearly as strong as fgA2 here, it can not mark a disabled text
    t.fgDisabled = setColorAlpha(t.fgA2, 0.45);
    t.hover = setColorAlpha(Qt::black, 0.06);

    return t;
}

QColor SystemPalette::accentColor() const
{
    if (!m_ctx)
        return MainCtx::defaultAccentColor();
    return m_ctx->accentColor();
}

void SystemPalette::makeLightPalette()
{
    m_isDark = false;
    m_tokens = DesignTokens::light(accentColor());
    makeDesignPalette();
}

void SystemPalette::makeDarkPalette()
{
    m_isDark = true;
    m_tokens = DesignTokens::dark(accentColor());
    makeDesignPalette();
}

void SystemPalette::makeDesignPalette()
{
    typedef ColorContext C;

    const DesignTokens& t = m_tokens;

    const QColor ink = m_isDark ? Qt::white : Qt::black;

    m_colorMap.clear();

    //base set
    {
        C::ColorSet CS = C::View;
        setColor(CS, C::Bg, C::Primary, C::Normal, t.bgB1);
        setColor(CS, C::Bg, C::Secondary, C::Normal, t.bgA4);

        setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA2);
        setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);

        setColor(CS, C::Fg, C::Secondary, C::Normal, t.fgA3);
        setColor(CS, C::Fg, C::Secondary, C::Disabled, t.fgDisabled);

        setColor(CS, C::Bg, C::Highlight, C::Normal, t.bgA2);
        setColor(CS, C::Fg, C::Highlight, C::Normal, t.fg1);

        setColor(CS, C::Bg, C::Negative, C::Normal, mixColor(t.negative, t.bgB1, 0.26f));
        setColor(CS, C::Fg, C::Negative, C::Normal, t.negative);

        setColor(CS, C::Bg, C::Neutral, C::Normal, mixColor(t.neutral, t.bgB1, 0.26f));
        setColor(CS, C::Fg, C::Neutral, C::Normal, t.neutral);

        setColor(CS, C::Bg, C::Positive, C::Normal, mixColor(t.positive, t.bgB1, 0.26f));
        setColor(CS, C::Fg, C::Positive, C::Normal, t.positive);

        setColor(CS, C::Decoration, C::VisualFocus, C::Normal, setColorAlpha(t.accent, 0.0));
        setColor(CS, C::Decoration, C::VisualFocus, C::Focused, t.accent);

        setColor(CS, C::Decoration, C::Border, C::Normal, t.dividerDim);
        setColor(CS, C::Decoration, C::Border, C::Focused, t.dividerBright);
        setColor(CS, C::Decoration, C::Border, C::Hovered, t.dividerBright);
        setColor(CS, C::Decoration, C::Border, C::Disabled, setColorAlpha(t.dividerDim, 0.0));

        setColor(CS, C::Decoration, C::Separator, C::Normal, t.dividerDim);

        setColor(CS, C::Decoration, C::Shadow, C::Normal, t.shadow);

        setColor(CS, C::Decoration, C::Accent, C::Normal, t.accent);
        setColor(CS, C::Fg, C::Link, C::Normal, t.accent);
    }

    //window banner & miniplayer
    {
        C::ColorSet CS = C::Window;
        setColor(CS, C::Bg, C::Primary, C::Normal, t.bgA3);
        setColor(CS, C::Bg, C::Secondary, C::Normal, t.bgA4);
        setColor(CS, C::Decoration, C::Border, C::Normal, t.dividerDim);
    }

    //badges
    {
        C::ColorSet CS = C::Badge;
        setColor(CS, C::Bg, C::Primary, C::Normal, t.bgB2Glass);
        setColor(CS, C::Fg, C::Primary, C::Normal, t.fg1);
    }

    //menubar
    {
        C::ColorSet CS = C::MenuBar;
        setColor(CS, C::Bg, C::Primary, C::Normal, setColorAlpha(t.bgA2, 0.0));
        setColor(CS, C::Bg, C::Primary, C::Focused, t.bgA2);
        setColor(CS, C::Bg, C::Primary, C::Hovered, t.bgA2);
        setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA2);
        setColor(CS, C::Fg, C::Primary, C::Disabled, t.fgDisabled);
    }

    //Item
    {
        C::ColorSet CS = C::Item;
        setColor(CS, C::Bg, C::Primary, C::Normal, Qt::transparent);
        setColor(CS, C::Bg, C::Primary, C::Focused, t.hover);
        setColor(CS, C::Bg, C::Primary, C::Hovered, t.hover);

        setColor(CS, C::Bg, C::Highlight, C::Normal, t.bgA2);
        setColor(CS, C::Bg, C::Highlight, C::Focused, mixColor(ink, t.bgA2, 0.04f));
        setColor(CS, C::Bg, C::Highlight, C::Hovered, mixColor(ink, t.bgA2, 0.04f));
        setColor(CS, C::Fg, C::Highlight, C::Normal, t.fg1);

        setColor(CS, C::Fg, C::Primary, C::Normal, t.fgA1);
        setColor(CS, C::Fg, C::Primary, C::Focused, t.fg2);
        setColor(CS, C::Fg, C::Primary, C::Hovered, t.fg2);
        setColor(CS, C::Fg, C::Secondary, C::Normal, t.fgA3);

        setColor(CS, C::Decoration, C::Indicator, C::Normal, t.accent);
    }

    //slider
    {
        C::ColorSet CS = C::Slider;
        setColor(CS, C::Decoration, C::Accent, C::Normal, t.accent);

        setColor(CS, C::Fg, C::Positive, C::Normal, t.positive);
        setColor(CS, C::Fg, C::Neutral, C::Normal, t.fgA4);
        setColor(CS, C::Fg, C::Negative, C::Normal, t.negative);
    }

    setControlColors(*this, m_tokens);
}

void SystemPalette::makeSystemPalette()
{
    if (!m_ctx)
    {
        //can't initialise system palette, fallback to default
        makeLightPalette();
        return;
    }

    auto palette = std::make_unique<ExternalPaletteImpl>(m_ctx, *this);
    if (!palette->init())
    {
        //can't initialise system palette, fallback to default
        makeLightPalette();
        return;
    }

    m_colorMap.clear();
    int ret = palette->update();
    if (ret != VLC_SUCCESS)
    {
        if (palette->isThemeDark())
            makeDarkPalette();
        else
            makeLightPalette();
    }
    else
    {
        m_isDark = palette->isThemeDark();
        m_tokens = m_isDark ? DesignTokens::dark(accentColor()) : DesignTokens::light(accentColor());
        setControlColors(*this, m_tokens);
    }

    m_palettePriv = std::move(palette);
}
