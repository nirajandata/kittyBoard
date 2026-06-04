#pragma once

#include <QString>
#include <QStringList>
#include <unordered_map>
#include <memory>
#include <cstdint>

struct WordEntry {
    QString word;
    uint32_t frequency;
};

struct QCharHash {
    std::size_t operator()(QChar c) const noexcept {
        return std::hash<char16_t>{}(c.unicode());
    }
};

struct QStringHash {
    std::size_t operator()(const QString &s) const noexcept {
        return std::hash<std::u16string>{}(s.toStdU16String());
    }
};

using BigramMap = std::unordered_map<QString, std::unordered_map<QString, uint32_t, QStringHash>, QStringHash>;

class SuggestionEngine {
public:
    SuggestionEngine();

    void loadDictionary(const QString &path);
    void loadUserData(const QString &path);
    void saveUserData(const QString &path) const;

    void learnWord(const QString &word, const QString &prevWord = QString());
    QStringList suggest(const QString &prefix, const QString &prevWord = QString(), int maxResults = 3) const;

private:
    struct TrieNode {
        std::unordered_map<QChar, std::unique_ptr<TrieNode>, QCharHash> children;
        uint32_t frequency = 0;
        bool isTerminal = false;
    };

    void insert(const QString &word, uint32_t frequency);
    void collectSuggestions(const TrieNode *node, const QString &prefix,
                            QList<WordEntry> &results) const;

    std::unique_ptr<TrieNode> m_root;
    BigramMap m_bigrams;
    QString m_userDataPath;
};
