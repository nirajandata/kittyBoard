#pragma once

#include <QObject>
#include <QPoint>
#include <QString>
#include <QStringList>
#include "SuggestionEngine.h"

class KeyboardSimulator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList suggestions READ suggestions NOTIFY suggestionsChanged)

public:
    explicit KeyboardSimulator(QObject *parent = nullptr);

    Q_INVOKABLE void setOwnWindowId(long long winId);

    Q_INVOKABLE void sendKey(const QString &key);
    Q_INVOKABLE void sendBackspace();
    Q_INVOKABLE void sendSpace();
    Q_INVOKABLE void sendEnter();

    Q_INVOKABLE void sendTab();
    Q_INVOKABLE void sendEscape();
    Q_INVOKABLE void sendDelete();
    Q_INVOKABLE void sendArrow(const QString &direction);

    Q_INVOKABLE void moveWindow(int x, int y);
    Q_INVOKABLE QPoint globalMouse() const;

    Q_INVOKABLE void applySuggestion(const QString &word);

    QStringList suggestions() const;

    void loadDictionary(const QString &path);
    void loadUserData(const QString &path);

signals:
    void moveWindowRequested(int x, int y);
    void suggestionsChanged();

private:
    void sendKeyCode(int keyCode);
    void runYdotool(const QStringList &args);
    void updateSuggestions();
    void commitCurrentWord();

    long long m_ownWindowId;
    QString m_ydotoolSocket;

    int m_currentWordLength = 0;
    QString m_currentWord;
    QString m_previousWord;
    QString m_prevWord2;

    SuggestionEngine m_engine;
    QStringList m_suggestions;
    QString m_userDataPath;
};