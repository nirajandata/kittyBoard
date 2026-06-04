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

class SuggestionEngine {
public:
    SuggestionEngine();

    void loadDictionary(const QString &path);
    void loadUserData(const QString &path);
    void saveUserData(const QString &path) const;

    void learnWord(const QString &word);
    QStringList suggest(const QString &prefix, int maxResults = 3) const;

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
    QString m_userDataPath;
};