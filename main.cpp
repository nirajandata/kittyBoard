#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QFile>
#include <QDir>

#include "ThemeManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    ThemeManager themeManager;
    // generate something


    // expose FIRST
    engine.rootContext()->setContextProperty(
        "ThemeManager",
        &themeManager
        );


    themeManager.loadTheme("Kiraboard/themes/dark.json");

     engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Kittyboard/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "QML failed to load";
        return -1;
    }

    return app.exec();
}