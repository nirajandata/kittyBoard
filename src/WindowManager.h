#pragma once

#include <QObject>
#include <QWindow>

class WindowManager : public QObject {
    Q_OBJECT

public:
    explicit WindowManager(QObject *parent = nullptr);

    Q_INVOKABLE void setWindowClickThrough(QWindow *window);
    Q_INVOKABLE void setWindowAlwaysOnTop(QWindow *window);
    Q_INVOKABLE void setWindowNoFocus(QWindow *window);

private:
    void setupX11Window(QWindow *window);
};
