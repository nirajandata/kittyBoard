#include "ThemeManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {}

QVariantMap ThemeManager::theme() const { return m_theme; }

void ThemeManager::loadTheme(const QString &path) {
    QFile file(path);
    currentThemePath = path;
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open theme:" << path;
        return;
    }
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    m_theme = doc.toVariant().toMap();
    emit themeChanged();
}

void ThemeManager::saveCurrentTheme()
{
    QFile file(currentThemePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Cannot write theme:" << currentThemePath;
        return;
    }
    QJsonDocument doc(QJsonObject::fromVariantMap(m_theme));
    file.write(doc.toJson(QJsonDocument::Indented));
}

QVariant ThemeManager::getThemeProperty(const QString &path) const {
    QStringList parts = path.split('.');
    QVariantMap current = m_theme;
    for (int i = 0; i < parts.size() - 1; ++i) {
        current = current.value(parts[i]).toMap();
    }
    return current.value(parts.last());
}

QVariantMap ThemeManager::deepSet(QVariantMap map, const QStringList &path, const QVariant &value) const {
    if (path.size() == 1) {
        map[path[0]] = value;
        return map;
    }
    QString key = path[0];
    QVariantMap nested = map.value(key).toMap();
    map[key] = deepSet(nested, path.mid(1), value);
    return map;
}

void ThemeManager::setThemeProperty(const QString &path, const QVariant &value) {
    m_theme = deepSet(m_theme, path.split('.'), value);
    emit themeChanged();
}