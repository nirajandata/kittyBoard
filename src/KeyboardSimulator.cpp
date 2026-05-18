#include "KeyboardSimulator.h"
#include <QProcess>
#include <QDebug>
#include <QMap>

KeyboardSimulator::KeyboardSimulator(QObject *parent)
    : QObject(parent) {}

void KeyboardSimulator::sendKey(const QString &key)
{
    // Map characters to xdotool key names
    static QMap<QString, QString> keyMap = {
        {"a", "a"}, {"b", "b"}, {"c", "c"}, {"d", "d"}, {"e", "e"},
        {"f", "f"}, {"g", "g"}, {"h", "h"}, {"i", "i"}, {"j", "j"},
        {"k", "k"}, {"l", "l"}, {"m", "m"}, {"n", "n"}, {"o", "o"},
        {"p", "p"}, {"q", "q"}, {"r", "r"}, {"s", "s"}, {"t", "t"},
        {"u", "u"}, {"v", "v"}, {"w", "w"}, {"x", "x"}, {"y", "y"},
        {"z", "z"},
        {"A", "shift+a"}, {"B", "shift+b"}, {"C", "shift+c"}, {"D", "shift+d"},
        {"E", "shift+e"}, {"F", "shift+f"}, {"G", "shift+g"}, {"H", "shift+h"},
        {"I", "shift+i"}, {"J", "shift+j"}, {"K", "shift+k"}, {"L", "shift+l"},
        {"M", "shift+m"}, {"N", "shift+n"}, {"O", "shift+o"}, {"P", "shift+p"},
        {"Q", "shift+q"}, {"R", "shift+r"}, {"S", "shift+s"}, {"T", "shift+t"},
        {"U", "shift+u"}, {"V", "shift+v"}, {"W", "shift+w"}, {"X", "shift+x"},
        {"Y", "shift+y"}, {"Z", "shift+z"},
        {"0", "0"}, {"1", "1"}, {"2", "2"}, {"3", "3"}, {"4", "4"},
        {"5", "5"}, {"6", "6"}, {"7", "7"}, {"8", "8"}, {"9", "9"},
        {" ", "space"},
    };

    QString keyName = keyMap.value(key.toLower(), key.toLower());
    
    QProcess process;
    process.start("xdotool", QStringList() << "key" << keyName);
    process.waitForFinished();

    if (process.exitCode() != 0) {
        qWarning() << "xdotool error:" << process.readAllStandardError();
    }
}

void KeyboardSimulator::sendBackspace()
{
    QProcess process;
    process.start("xdotool", QStringList() << "key" << "BackSpace");
    process.waitForFinished();
}

void KeyboardSimulator::sendSpace()
{
    QProcess process;
    process.start("xdotool", QStringList() << "key" << "space");
    process.waitForFinished();
}

void KeyboardSimulator::sendEnter()
{
    QProcess process;
    process.start("xdotool", QStringList() << "key" << "Return");
    process.waitForFinished();
}
