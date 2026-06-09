#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class ThemeManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadTheme(const QString &path);
    Q_INVOKABLE void saveCurrentTheme();
    Q_INVOKABLE void resetTheme();
    Q_INVOKABLE QVariant getThemeProperty(const QString &path) const;
    Q_INVOKABLE void setThemeProperty(const QString &path, const QVariant &value);

    QVariantMap theme() const;

signals:
    void themeChanged();

private:
    QVariantMap m_theme;
    QString m_currentThemePath;
    QString m_defaultThemePath;
    QVariantMap deepSet(QVariantMap map, const QStringList &path, const QVariant &value) const;
};