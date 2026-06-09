#pragma once

#include <QList>
#include <QMap>
#include <QSet>
#include <QString>
#include <QStringList>
#include <map>
#include <memory>
#include <vector>

struct TrieNode
{
    std::map<QChar, std::unique_ptr<TrieNode>> children;
    bool isTerminal = false;
    uint32_t frequency = 0;
};

struct WordEntry
{
    QString word;
    uint32_t frequency = 0;
    int editDistance = 0;
};

class SuggestionEngine
{
public:
    SuggestionEngine();

    void insert(const QString &word, uint32_t frequency);
    void loadDictionary(const QString &path);

    void loadUserData(const QString &path);
    void saveUserData(const QString &path) const;
    void learnWord(const QString &word, const QString &prevWord = {}, const QString &prevWord2 = {});

    QStringList suggest(const QString &prefix,
                        const QString &prevWord = {},
                        const QString &prevWord2 = {},
                        int maxResults = 5,
                        int maxEditDist = 2) const;

private:
    void collectSuggestions(const TrieNode *node,
                            const QString &prefix,
                            QList<WordEntry> &results) const;

    void collectFuzzy(const TrieNode *node,
                      QChar ch,
                      const QString &query,
                      const QString &currentWord,
                      std::vector<int> prevRow,
                      int maxDist,
                      QList<WordEntry> &results) const;

    std::unique_ptr<TrieNode> m_root;
    QMap<QString, QMap<QString, uint32_t>> m_bigrams;
    QMap<QString, QMap<QString, QMap<QString, uint32_t>>> m_trigrams;
    QString m_userDataPath;
};