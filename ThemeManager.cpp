#include "ThemeManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent) {}

void ThemeManager::loadTheme(const QString &path)
{
    QFile file(path);

    if (!file.exists()) {
        qWarning() << "[Theme] File not found:" << path;
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[Theme] Cannot open file:" << path;
        return;
    }

    QByteArray data = file.readAll();

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);

    if (err.error != QJsonParseError::NoError) {
        qWarning() << "[Theme] JSON error:" << err.errorString();
        return;
    }

    m_theme = doc.object().toVariantMap();

    qDebug() << "[Theme] Loaded!";
    qDebug() << "[Theme] Keys:" << m_theme.keys();

    emit themeChanged();
}