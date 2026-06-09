#include "ThemeManager.h"
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent)
    , m_currentThemePath("Kittyboard/themes/neon.json")
    , m_defaultThemePath(":/qt/qml/Kittyboard/themes/neon.json")
{}

QVariantMap ThemeManager::theme() const
{
    return m_theme;
}

void ThemeManager::loadTheme(const QString &path)
{
    QString localPath = path;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(path).toLocalFile();
    }

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open theme:" << localPath;
        return;
    }
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    m_theme = doc.toVariant().toMap();
    m_currentThemePath = localPath;
    emit themeChanged();
}

void ThemeManager::saveCurrentTheme()
{
    QFile file(m_currentThemePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Cannot write theme:" << m_currentThemePath;
        return;
    }
    QJsonDocument doc(QJsonObject::fromVariantMap(m_theme));
    file.write(doc.toJson(QJsonDocument::Indented));
}

void ThemeManager::resetTheme()
{
    loadTheme(m_defaultThemePath);
}

QVariant ThemeManager::getThemeProperty(const QString &path) const
{
    QStringList parts = path.split('.');
    QVariantMap current = m_theme;
    for (int i = 0; i < parts.size() - 1; ++i) {
        current = current.value(parts[i]).toMap();
        if (current.isEmpty())
            return QVariant();
    }
    return current.value(parts.last());
}

QVariantMap ThemeManager::deepSet(QVariantMap map,
                                  const QStringList &path,
                                  const QVariant &value) const
{
    if (path.size() == 1) {
        map[path[0]] = value;
        return map;
    }
    QString key = path[0];
    QVariantMap nested = map.value(key).toMap();
    map[key] = deepSet(nested, path.mid(1), value);
    return map;
}

void ThemeManager::setThemeProperty(const QString &path, const QVariant &value)
{
    m_theme = deepSet(m_theme, path.split('.'), value);
    emit themeChanged();
}