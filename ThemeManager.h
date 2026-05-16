#pragma once

#include <QObject>
#include <QVariantMap>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    QVariantMap theme() const { return m_theme; }

    Q_INVOKABLE void loadTheme(const QString &path);

signals:
    void themeChanged();

private:
    QVariantMap m_theme;
};