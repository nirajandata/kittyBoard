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


    engine.rootContext()->setContextProperty(
        "ThemeManager",
        &themeManager
        );


    themeManager.loadTheme("Kittyboard/themes/dark.json");

     engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Kittyboard/qml/Main.qml")));
    qDebug() << "App dir:" << QCoreApplication::applicationDirPath();
    qDebug() << "Exists:" << QFile::exists("Kittyboard/themes/dark.json");

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "QML failed to load";
        return -1;
    }

    return app.exec();
}