#pragma once

#include <QObject>
#include <QString>

class KeyboardSimulator : public QObject {
    Q_OBJECT

public:
    explicit KeyboardSimulator(QObject *parent = nullptr);

    Q_INVOKABLE void sendKey(const QString &key);
    Q_INVOKABLE void sendBackspace();
    Q_INVOKABLE void sendSpace();
    Q_INVOKABLE void sendEnter();

private:
    void sendKeyEvent(int keyCode, bool shift = false);
};
