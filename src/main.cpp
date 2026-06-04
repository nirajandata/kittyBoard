#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QMargins>
#include <QFile>
#include <QDir>

#include <LayerShellQt/Window>

#include "ThemeManager.h"
#include "KeyboardSimulator.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    QQuickWindow::setDefaultAlphaBuffer(true);

    ThemeManager themeManager;
    KeyboardSimulator keyboardSimulator;

    engine.rootContext()->setContextProperty("ThemeManager", &themeManager);
    engine.rootContext()->setContextProperty("KeyboardSimulator", &keyboardSimulator);

    qDebug() << "Dict path exists:" << QFile::exists("Kittyboard/assets/english_10k.txt");
    qDebug() << "Working dir:" << QDir::currentPath();

    themeManager.loadTheme("Kittyboard/themes/neon.json");
    keyboardSimulator.loadDictionary("Kittyboard/assets/english_10k.txt");



    qDebug() << "Dict test:" << keyboardSimulator.suggestions();

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [&](QObject *obj, const QUrl &) {
            QQuickWindow *window = qobject_cast<QQuickWindow *>(obj);
            if (!window) return;

            auto *layerWindow = LayerShellQt::Window::get(window);
            layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
            layerWindow->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
            layerWindow->setAnchors(LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorTop));
            layerWindow->setExclusiveZone(0);

            QObject::connect(&keyboardSimulator, &KeyboardSimulator::moveWindowRequested,
                             window, [layerWindow](int x, int y) {
                                 layerWindow->setMargins(QMargins(x, y, 0, 0));
                             }, Qt::DirectConnection);

            QObject::connect(window, &QQuickWindow::frameSwapped,
                             &keyboardSimulator, &KeyboardSimulator::onFrameSwapped,
                             Qt::DirectConnection);

            keyboardSimulator.setOwnWindowId(window->winId());
            window->show();
        },
        Qt::QueuedConnection
        );

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Kittyboard/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
