#include "KeyboardSimulator.h"
#include <QProcess>
#include <QDebug>
#include <QMap>

// Linux key codes from /usr/include/linux/input-event-codes.h
// ydotool format: "KEYCODE:1 KEYCODE:0" (press then release)
static const QMap<QString, int> keyCodeMap = {
    {"a", 30}, {"b", 48}, {"c", 46}, {"d", 32}, {"e", 18},
    {"f", 33}, {"g", 34}, {"h", 35}, {"i", 23}, {"j", 36},
    {"k", 37}, {"l", 38}, {"m", 50}, {"n", 49}, {"o", 24},
    {"p", 25}, {"q", 16}, {"r", 19}, {"s", 31}, {"t", 20},
    {"u", 22}, {"v", 47}, {"w", 17}, {"x", 45}, {"y", 21},
    {"z", 44},
    {"0", 11}, {"1", 2},  {"2", 3},  {"3", 4},  {"4", 5},
    {"5", 6},  {"6", 7},  {"7", 8},  {"8", 9},  {"9", 10},
    {"space",     57},
    {"backspace",  14},
    {"enter",      28},
    {"shift",      42}, // left shift
};

KeyboardSimulator::KeyboardSimulator(QObject *parent)
    : QObject(parent), m_ownWindowId(0)
{
    // Resolve the ydotool socket path. On Arch it's a user service so the
    // socket lives under /run/user/<uid>/. We set this in the environment of
    // every QProcess we spawn so the app works even if the user hasn't exported
    // YDOTOOL_SOCKET in their shell profile.
    QString uid = QString::number(getuid());
    m_ydotoolSocket = QString("/run/user/%1/.ydotool_socket").arg(uid);
    qDebug() << "[KeyboardSimulator] ydotool socket:" << m_ydotoolSocket;
}

void KeyboardSimulator::setOwnWindowId(long long winId)
{
    m_ownWindowId = winId;
    qDebug() << "[KeyboardSimulator] Own window ID:" << m_ownWindowId;
}

// Sets up a QProcess with the correct YDOTOOL_SOCKET env var and runs ydotool.
void KeyboardSimulator::runYdotool(const QStringList &args)
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("YDOTOOL_SOCKET", m_ydotoolSocket);

    QProcess process;
    process.setProcessEnvironment(env);
    process.start("ydotool", args);
    process.waitForFinished(2000);

    if (process.exitCode() != 0) {
        qWarning() << "[KeyboardSimulator] ydotool error:" << process.readAllStandardError();
    }
}

// ydotool injects into /dev/uinput — goes straight to the kernel input layer.
// Whatever window currently has focus receives the keystroke.
// Since layer-shell KeyboardInteractivityNone means our keyboard window
// NEVER gets focus, the target app always keeps focus. No window tracking needed.
void KeyboardSimulator::sendKeyCode(int keyCode)
{
    runYdotool(QStringList()
               << "key"
               << QString("%1:1").arg(keyCode)
               << QString("%1:0").arg(keyCode));
}

void KeyboardSimulator::sendKey(const QString &key)
{
    QString lower = key.toLower();
    bool isUpper  = (key != lower);

    if (!keyCodeMap.contains(lower)) {
        qWarning() << "[KeyboardSimulator] Unknown key:" << key;
        return;
    }

    int code = keyCodeMap[lower];

    if (isUpper) {
        int shift = keyCodeMap["shift"];
        runYdotool(QStringList()
                   << "key"
                   << QString("%1:1").arg(shift)
                   << QString("%1:1").arg(code)
                   << QString("%1:0").arg(code)
                   << QString("%1:0").arg(shift));
    } else {
        sendKeyCode(code);
    }
}

void KeyboardSimulator::sendBackspace()
{
    sendKeyCode(keyCodeMap["backspace"]);
}

void KeyboardSimulator::sendSpace()
{
    sendKeyCode(keyCodeMap["space"]);
}

void KeyboardSimulator::sendEnter()
{
    sendKeyCode(keyCodeMap["enter"]);
}