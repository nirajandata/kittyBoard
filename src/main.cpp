#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QFile>
#include <QDir>

#include "ThemeManager.h"
#include "KeyboardSimulator.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    ThemeManager themeManager;
    KeyboardSimulator keyboardSimulator;

    engine.rootContext()->setContextProperty("ThemeManager", &themeManager);
    engine.rootContext()->setContextProperty("KeyboardSimulator", &keyboardSimulator);

    themeManager.loadTheme("qrc:/Kittyboard/themes/dark.json");

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Kittyboard/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "QML failed to load";
        return -1;
    }

    return app.exec();
}
