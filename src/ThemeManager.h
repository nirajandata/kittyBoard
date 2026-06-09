#pragma once

#include <QObject>
#include <QVariantMap>
#include <QString>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap theme READ theme NOTIFY themeChanged)

public:
    QString currentThemePath;
    explicit ThemeManager(QObject *parent = nullptr);

    Q_INVOKABLE void loadTheme(const QString &path);
    Q_INVOKABLE void saveCurrentTheme();
    Q_INVOKABLE QVariant getThemeProperty(const QString &path) const;
    Q_INVOKABLE void setThemeProperty(const QString &path, const QVariant &value);

    QVariantMap theme() const;

signals:
    void themeChanged();

private:
    QVariantMap m_theme;
    QVariantMap deepSet(QVariantMap map, const QStringList &path, const QVariant &value) const;
};