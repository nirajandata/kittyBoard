#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QDebug>

#include <LayerShellQt/Window>

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

    themeManager.loadTheme("Kittyboard/themes/dark.json");

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [&](QObject *obj, const QUrl &) {
            QQuickWindow *window = qobject_cast<QQuickWindow *>(obj);
            if (!window) return;

            auto *layerWindow = LayerShellQt::Window::get(window);

            // Overlay layer floats above all normal windows
            layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);

            // No keyboard interactivity — never steals focus
            layerWindow->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);

            // No anchors = free floating, compositor places it at 0,0 initially
            layerWindow->setAnchors({});

            // No exclusive zone = doesn't push other windows away
            layerWindow->setExclusiveZone(0);

            keyboardSimulator.setOwnWindowId(window->winId());
            qDebug() << "[main] Layer-shell configured (floating)";

            window->show();
        },
        Qt::QueuedConnection
        );

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Kittyboard/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "QML failed to load";
        return -1;
    }

    return app.exec();
}