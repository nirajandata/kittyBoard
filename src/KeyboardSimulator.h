#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QPoint>

class KeyboardSimulator : public QObject {
    Q_OBJECT

public:
    explicit KeyboardSimulator(QObject *parent = nullptr);

    Q_INVOKABLE void setOwnWindowId(long long winId);

    Q_INVOKABLE void sendKey(const QString &key);
    Q_INVOKABLE void sendBackspace();
    Q_INVOKABLE void sendSpace();
    Q_INVOKABLE void sendEnter();

    Q_INVOKABLE void moveWindow(int x, int y);
    Q_INVOKABLE QPoint globalMouse() const;

signals:
    void moveWindowRequested(int x, int y);

public slots:
    void onFrameSwapped();

private:
    void sendKeyCode(int keyCode);
    void runYdotool(const QStringList &args);

    long long m_ownWindowId;
    QString m_ydotoolSocket;

    bool m_movePending = false;
    int m_pendingX = 0;
    int m_pendingY = 0;
};