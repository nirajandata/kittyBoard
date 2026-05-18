#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QProcessEnvironment>
#include <unistd.h> // getuid()

class KeyboardSimulator : public QObject {
    Q_OBJECT

public:
    explicit KeyboardSimulator(QObject *parent = nullptr);

    Q_INVOKABLE void setOwnWindowId(long long winId);

    // On Wayland with layer-shell, the keyboard never gets focus,
    // so storeExternalFocus / restoreExternalFocus are no longer needed.
    // ydotool injects directly into the kernel input layer — no window
    // targeting required. These are kept as no-ops for API compatibility.
    Q_INVOKABLE void storeExternalFocus() {}

    Q_INVOKABLE void sendKey(const QString &key);
    Q_INVOKABLE void sendBackspace();
    Q_INVOKABLE void sendSpace();
    Q_INVOKABLE void sendEnter();

private:
    void sendKeyCode(int keyCode);
    void runYdotool(const QStringList &args);

    long long m_ownWindowId;
    QString   m_ydotoolSocket;
};