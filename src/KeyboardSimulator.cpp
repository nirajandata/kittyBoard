#include "KeyboardSimulator.h"
#include <QProcess>
#include <QProcessEnvironment>
#include <QHash>
#include <QCursor>
#include <QStandardPaths>
#include <QDir>
#include <unistd.h>

static const QHash<QString, int> keyCodeMap = {
    {"a", 30}, {"b", 48}, {"c", 46}, {"d", 32}, {"e", 18},
    {"f", 33}, {"g", 34}, {"h", 35}, {"i", 23}, {"j", 36},
    {"k", 37}, {"l", 38}, {"m", 50}, {"n", 49}, {"o", 24},
    {"p", 25}, {"q", 16}, {"r", 19}, {"s", 31}, {"t", 20},
    {"u", 22}, {"v", 47}, {"w", 17}, {"x", 45}, {"y", 21},
    {"z", 44}, {"0", 11}, {"1", 2},  {"2", 3},  {"3", 4},
    {"4", 5},  {"5", 6},  {"6", 7},  {"7", 8},  {"8", 9},
    {"9", 10}, {"space", 57}, {"backspace", 14}, {"enter", 28},
    {"shift", 42}
};

KeyboardSimulator::KeyboardSimulator(QObject *parent)
    : QObject(parent), m_ownWindowId(0) {
    m_ydotoolSocket = QString("/run/user/%1/.ydotool_socket").arg(getuid());

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_userDataPath = dataDir + "/learned_words.json";
    m_engine.loadUserData(m_userDataPath);
}

void KeyboardSimulator::loadDictionary(const QString &path) {
    m_engine.loadDictionary(path);
}

void KeyboardSimulator::loadUserData(const QString &path) {
    m_userDataPath = path;
    m_engine.loadUserData(path);
}

QStringList KeyboardSimulator::suggestions() const {
    return m_suggestions;
}

void KeyboardSimulator::updateSuggestions() {
    QStringList next = m_currentWord.isEmpty()
        ? QStringList{}
        : m_engine.suggest(m_currentWord, m_previousWord, 3);

    if (next != m_suggestions) {
        m_suggestions = next;
        emit suggestionsChanged();
    }
}

void KeyboardSimulator::commitCurrentWord() {
    if (!m_currentWord.isEmpty()) {
        m_engine.learnWord(m_currentWord, m_previousWord);
        m_previousWord = m_currentWord;
    }
    m_currentWord.clear();
    m_currentWordLength = 0;
}

void KeyboardSimulator::setOwnWindowId(long long winId) {
    m_ownWindowId = winId;
}

void KeyboardSimulator::moveWindow(int x, int y) {
    m_pendingX = x;
    m_pendingY = y;
    m_movePending = true;
}

void KeyboardSimulator::onFrameSwapped() {
    if (m_movePending) {
        m_movePending = false;
        emit moveWindowRequested(m_pendingX, m_pendingY);
    }
}

QPoint KeyboardSimulator::globalMouse() const {
    return QCursor::pos();
}

void KeyboardSimulator::runYdotool(const QStringList &args) {
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("YDOTOOL_SOCKET", m_ydotoolSocket);

    QProcess process;
    process.setProcessEnvironment(env);
    process.start("ydotool", args);
    process.waitForFinished(2000);
}

void KeyboardSimulator::sendKeyCode(int keyCode) {
    runYdotool({"key", QString("%1:1").arg(keyCode), QString("%1:0").arg(keyCode)});
}

void KeyboardSimulator::sendKey(const QString &key) {
    QString lower = key.toLower();
    bool isUpper = (key != lower);

    auto it = keyCodeMap.find(lower);
    if (it == keyCodeMap.end()) return;

    int code = it.value();

    if (isUpper) {
        int shift = keyCodeMap.value("shift");
        runYdotool({
            "key",
            QString("%1:1").arg(shift),
            QString("%1:1").arg(code),
            QString("%1:0").arg(code),
            QString("%1:0").arg(shift)
        });
    } else {
        sendKeyCode(code);
    }

    m_currentWordLength++;
    m_currentWord += lower;
    updateSuggestions();
}

void KeyboardSimulator::sendBackspace() {
    sendKeyCode(keyCodeMap.value("backspace"));

    if (m_currentWordLength > 0) {
        m_currentWordLength--;
        m_currentWord.chop(1);
    }

    updateSuggestions();
}

void KeyboardSimulator::sendSpace() {
    sendKeyCode(keyCodeMap.value("space"));
    commitCurrentWord();
    updateSuggestions();
}

void KeyboardSimulator::sendEnter() {
    sendKeyCode(keyCodeMap.value("enter"));
    commitCurrentWord();
    m_previousWord.clear();
    updateSuggestions();
}

void KeyboardSimulator::applySuggestion(const QString &word) {
    for (int i = 0; i < m_currentWordLength; ++i) {
        sendKeyCode(keyCodeMap.value("backspace"));
    }

    m_engine.learnWord(word, m_previousWord);
    m_previousWord = word.toLower().trimmed();
    m_currentWord.clear();
    m_currentWordLength = 0;

    for (const QChar &c : word) {
        sendKey(QString(c));
    }

    m_currentWord.clear();
    m_currentWordLength = 0;

    sendKeyCode(keyCodeMap.value("space"));
    updateSuggestions();
}
