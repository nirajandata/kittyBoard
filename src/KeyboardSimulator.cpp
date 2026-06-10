#include "KeyboardSimulator.h"
#include <QCursor>
#include <QDir>
#include <QHash>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <unistd.h>

static const QHash<QString, int> keyCodeMap
    = {{"a", 30},     {"b", 48},    {"c", 46},     {"d", 32},         {"e", 18},
       {"f", 33},     {"g", 34},    {"h", 35},     {"i", 23},         {"j", 36},
       {"k", 37},     {"l", 38},    {"m", 50},     {"n", 49},         {"o", 24},
       {"p", 25},     {"q", 16},    {"r", 19},     {"s", 31},         {"t", 20},
       {"u", 22},     {"v", 47},    {"w", 17},     {"x", 45},         {"y", 21},
       {"z", 44},     {"0", 11},    {"1", 2},      {"2", 3},          {"3", 4},
       {"4", 5},      {"5", 6},     {"6", 7},      {"7", 8},          {"8", 9},
       {"9", 10},     {"`", 41},    {"-", 12},     {"=", 13},         {"[", 26},
       {"]", 27},     {"\\", 43},   {";", 39},     {"'", 40},         {",", 51},
       {".", 52},     {"/", 53},    {"space", 57}, {"backspace", 14}, {"enter", 28},
       {"shift", 42}, {"tab", 15},  {"esc", 1},    {"escape", 1},     {"delete", 111},
       {"del", 111},  {"ctrl", 29}, {"alt", 56},   {"super", 125},    {"meta", 125},
       {"win", 125},  {"up", 103},  {"down", 108}, {"left", 105},     {"right", 106}};

static const QHash<QString, QString> shiftSymbolMap = {{"!", "1"}, {"@", "2"},  {"#", "3"},
                                                       {"$", "4"}, {"%", "5"},  {"^", "6"},
                                                       {"&", "7"}, {"*", "8"},  {"(", "9"},
                                                       {")", "0"}, {"_", "-"},  {"+", "="},
                                                       {"{", "["}, {"}", "]"},  {"|", "\\"},
                                                       {":", ";"}, {"\"", "'"}, {"<", ","},
                                                       {">", "."}, {"?", "/"},  {"~", "`"}};

KeyboardSimulator::KeyboardSimulator(QObject *parent)
    : QObject(parent)
    , m_ownWindowId(0)
{
    m_ydotoolSocket = QString("/run/user/%1/.ydotool_socket").arg(getuid());

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_userDataPath = dataDir + "/learned_words.json";
    m_engine.loadUserData(m_userDataPath);
}

void KeyboardSimulator::loadDictionary(const QString &path)
{
    m_engine.loadDictionary(path);
}

void KeyboardSimulator::loadUserData(const QString &path)
{
    m_userDataPath = path;
    m_engine.loadUserData(path);
}

QStringList KeyboardSimulator::suggestions() const
{
    return m_suggestions;
}

void KeyboardSimulator::updateSuggestions()
{
    QStringList next;
    if (m_currentWord.isEmpty()) {
        if (!m_previousWord.isEmpty())
            next = m_engine.suggestNextWords(m_previousWord, m_prevWord2, 3);
    } else {
        next = m_engine.suggest(m_currentWord, m_previousWord, m_prevWord2, 3);
    }

    if (next != m_suggestions) {
        m_suggestions = next;
        emit suggestionsChanged();
    }
}

void KeyboardSimulator::commitCurrentWord()
{
    if (!m_currentWord.isEmpty()) {
        m_engine.learnWord(m_currentWord, m_previousWord, m_prevWord2);
        m_prevWord2 = m_previousWord;
        m_previousWord = m_currentWord;
        m_engine.saveUserData(m_userDataPath);
    }
    m_currentWord.clear();
    m_currentWordLength = 0;
}

void KeyboardSimulator::setOwnWindowId(long long winId)
{
    m_ownWindowId = winId;
}

void KeyboardSimulator::moveWindow(int x, int y)
{
    emit moveWindowRequested(x, y);
}

QPoint KeyboardSimulator::globalMouse() const
{
    return QCursor::pos();
}

void KeyboardSimulator::runYdotool(const QStringList &args)
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("YDOTOOL_SOCKET", m_ydotoolSocket);

    QProcess process;
    process.setProcessEnvironment(env);
    process.start("ydotool", args);
    process.waitForFinished(2000);
}

void KeyboardSimulator::sendKeyCode(int keyCode)
{
    runYdotool({"key", QString("%1:1").arg(keyCode), QString("%1:0").arg(keyCode)});
}

void KeyboardSimulator::sendKey(const QString &key)
{
    QString k = key;
    bool needsShift = false;

    auto shiftIt = shiftSymbolMap.find(key);
    if (shiftIt != shiftSymbolMap.end()) {
        k = shiftIt.value();
        needsShift = true;
    }

    QString lower = k.toLower();
    bool isUpper = (k != lower) || needsShift;

    auto it = keyCodeMap.find(lower);
    if (it == keyCodeMap.end()) {
        qWarning() << "Unknown key:" << key;
        return;
    }

    int code = it.value();

    if (isUpper) {
        int shift = keyCodeMap.value("shift");
        runYdotool({"key",
                    QString("%1:1").arg(shift),
                    QString("%1:1").arg(code),
                    QString("%1:0").arg(code),
                    QString("%1:0").arg(shift)});
    } else {
        sendKeyCode(code);
    }

    bool isWordChar = lower.length() == 1
                      && ((lower[0] >= 'a' && lower[0] <= 'z')
                          || (lower[0] >= '0' && lower[0] <= '9'));
    if (isWordChar) {
        m_currentWordLength++;
        m_currentWord += lower;
    }
    updateSuggestions();
}

void KeyboardSimulator::sendBackspace()
{
    sendKeyCode(keyCodeMap.value("backspace"));

    if (m_currentWordLength > 0) {
        m_currentWordLength--;
        m_currentWord.chop(1);
    }

    updateSuggestions();
}

void KeyboardSimulator::sendSpace()
{
    sendKeyCode(keyCodeMap.value("space"));
    commitCurrentWord();
    updateSuggestions();
}

void KeyboardSimulator::sendEnter()
{
    sendKeyCode(keyCodeMap.value("enter"));
    commitCurrentWord();
    updateSuggestions();
}

void KeyboardSimulator::sendTab()
{
    sendKeyCode(keyCodeMap.value("tab"));
}

void KeyboardSimulator::sendEscape()
{
    sendKeyCode(keyCodeMap.value("esc"));
}

void KeyboardSimulator::sendDelete()
{
    sendKeyCode(keyCodeMap.value("delete"));
}

void KeyboardSimulator::sendArrow(const QString &direction)
{
    QString d = direction.toLower();
    if (d == "up")
        sendKeyCode(103);
    else if (d == "down")
        sendKeyCode(108);
    else if (d == "left")
        sendKeyCode(105);
    else if (d == "right")
        sendKeyCode(106);
}

void KeyboardSimulator::sendChord(const QStringList &modifiers, const QString &key)
{
    QString k = key;
    bool needsShift = false;

    auto shiftIt = shiftSymbolMap.find(key);
    if (shiftIt != shiftSymbolMap.end()) {
        k = shiftIt.value();
        needsShift = true;
    }

    QString lower = k.toLower();

    auto it = keyCodeMap.find(lower);
    if (it == keyCodeMap.end()) {
        qWarning() << "Unknown key for chord:" << key;
        return;
    }

    int keyCode = it.value();

    QStringList args = {"key"};

    QList<int> modCodes;
    for (const QString &mod : modifiers) {
        QString m = mod.toLower();
        if (keyCodeMap.contains(m)) {
            int mc = keyCodeMap.value(m);
            modCodes.append(mc);
            args << QString("%1:1").arg(mc);
        }
    }

    if (needsShift) {
        int shift = keyCodeMap.value("shift");
        if (!modCodes.contains(shift)) {
            modCodes.append(shift);
            args << QString("%1:1").arg(shift);
        }
    }

    args << QString("%1:1").arg(keyCode);
    args << QString("%1:0").arg(keyCode);

    for (int i = modCodes.size() - 1; i >= 0; --i)
        args << QString("%1:0").arg(modCodes[i]);

    runYdotool(args);
}

void KeyboardSimulator::applySuggestion(const QString &word)
{
    for (int i = 0; i < m_currentWordLength; ++i) {
        sendKeyCode(keyCodeMap.value("backspace"));
    }

    m_engine.learnWord(word, m_previousWord, m_prevWord2);
    m_prevWord2 = m_previousWord;
    m_previousWord = word.toLower().trimmed();
    m_currentWord.clear();
    m_currentWordLength = 0;

    for (const QChar &c : word) {
        sendKey(QString(c));
    }

    m_currentWord.clear();
    m_currentWordLength = 0;

    sendKeyCode(keyCodeMap.value("space"));
    m_engine.saveUserData(m_userDataPath);
    updateSuggestions();
}