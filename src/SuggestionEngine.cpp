#include "SuggestionEngine.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTextStream>
#include <algorithm>
#include <numeric>

SuggestionEngine::SuggestionEngine()
    : m_root(std::make_unique<TrieNode>())
{}

void SuggestionEngine::insert(const QString &word, uint32_t frequency)
{
    if (word.isEmpty())
        return;

    TrieNode *node = m_root.get();
    for (const QChar &ch : word) {
        QChar lower = ch.toLower();
        auto &child = node->children[lower];
        if (!child) {
            child = std::make_unique<TrieNode>();
        }
        node = child.get();
    }
    node->isTerminal = true;
    node->frequency = std::max(node->frequency, frequency);
}

void SuggestionEngine::loadDictionary(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty())
            continue;

        QStringList parts = line.split('\t');
        QString word = parts.at(0).toLower();
        uint32_t freq = (parts.size() > 1) ? parts.at(1).toUInt() : 1;

        if (!word.isEmpty())
            insert(word, freq);
    }
}

void SuggestionEngine::loadUserData(const QString &path)
{
    m_userDataPath = path;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return;

    QJsonObject root = doc.object();

    QJsonObject words = root.value("words").toObject();
    for (auto it = words.begin(); it != words.end(); ++it)
        insert(it.key(), static_cast<uint32_t>(it.value().toInt()));

    QJsonObject bigrams = root.value("bigrams").toObject();
    for (auto it = bigrams.begin(); it != bigrams.end(); ++it) {
        QJsonObject follows = it.value().toObject();
        for (auto jt = follows.begin(); jt != follows.end(); ++jt)
            m_bigrams[it.key()][jt.key()] = static_cast<uint32_t>(jt.value().toInt());
    }

    QJsonObject trigrams = root.value("trigrams").toObject();
    for (auto it = trigrams.begin(); it != trigrams.end(); ++it) {
        QJsonObject mid = it.value().toObject();
        for (auto jt = mid.begin(); jt != mid.end(); ++jt) {
            QJsonObject follows = jt.value().toObject();
            for (auto kt = follows.begin(); kt != follows.end(); ++kt)
                m_trigrams[it.key()][jt.key()][kt.key()] = static_cast<uint32_t>(kt.value().toInt());
        }
    }
}

void SuggestionEngine::saveUserData(const QString &path) const
{
    QJsonObject words;
    QList<WordEntry> all;
    collectSuggestions(m_root.get(), QString(), all);
    for (const WordEntry &entry : all)
        words.insert(entry.word, static_cast<int>(entry.frequency));

    QJsonObject bigrams;
    for (auto it = m_bigrams.constBegin(); it != m_bigrams.constEnd(); ++it) {
        QJsonObject followObj;
        for (auto jt = it.value().constBegin(); jt != it.value().constEnd(); ++jt)
            followObj.insert(jt.key(), static_cast<int>(jt.value()));
        bigrams.insert(it.key(), followObj);
    }

    QJsonObject trigrams;
    for (auto it = m_trigrams.constBegin(); it != m_trigrams.constEnd(); ++it) {
        QJsonObject midObj;
        for (auto jt = it.value().constBegin(); jt != it.value().constEnd(); ++jt) {
            QJsonObject followObj;
            for (auto kt = jt.value().constBegin(); kt != jt.value().constEnd(); ++kt)
                followObj.insert(kt.key(), static_cast<int>(kt.value()));
            midObj.insert(jt.key(), followObj);
        }
        trigrams.insert(it.key(), midObj);
    }

    QJsonObject root;
    root.insert("words", words);
    root.insert("bigrams", bigrams);
    root.insert("trigrams", trigrams);

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
}

void SuggestionEngine::learnWord(const QString &word,
                                 const QString &prevWord,
                                 const QString &prevWord2)
{
    QString lower = word.toLower().trimmed();
    if (lower.isEmpty() || lower.size() < 2)
        return;

    TrieNode *node = m_root.get();
    for (const QChar &ch : lower) {
        auto &child = node->children[ch];
        if (!child) {
            child = std::make_unique<TrieNode>();
        }
        node = child.get();
    }
    node->isTerminal = true;
    node->frequency += 1;

    if (!prevWord.isEmpty()) {
        QString prev = prevWord.toLower().trimmed();
        if (!prev.isEmpty())
            m_bigrams[prev][lower] += 1;

        if (!prevWord2.isEmpty()) {
            QString prev2 = prevWord2.toLower().trimmed();
            if (!prev2.isEmpty())
                m_trigrams[prev2][prev][lower] += 1;
        }
    }
}

void SuggestionEngine::collectSuggestions(const TrieNode *node,
                                          const QString &prefix,
                                          QList<WordEntry> &results) const
{
    if (!node)
        return;

    if (node->isTerminal)
        results.append({prefix, node->frequency, 0});

    for (const auto &[ch, childNode] : node->children) {
        collectSuggestions(childNode.get(), prefix + ch, results);
    }
}

void SuggestionEngine::collectFuzzy(const TrieNode *node,
                                    QChar ch,
                                    const QString &query,
                                    const QString &currentWord,
                                    std::vector<int> prevRow,
                                    int maxDist,
                                    QList<WordEntry> &results) const
{
    const int cols = static_cast<int>(prevRow.size());

    std::vector<int> currentRow(cols);
    currentRow[0] = prevRow[0] + 1;

    for (int col = 1; col < cols; ++col) {
        int insertCost = currentRow[col - 1] + 1;
        int deleteCost = prevRow[col] + 1;
        int replaceCost = prevRow[col - 1] + (query[col - 1] == ch ? 0 : 1);
        currentRow[col] = std::min({insertCost, deleteCost, replaceCost});
    }

    if (node->isTerminal) {
        int dist = currentRow.back();
        if (dist > 0 && dist <= maxDist)
            results.append({currentWord, node->frequency, dist});
    }

    if (*std::min_element(currentRow.begin(), currentRow.end()) > maxDist)
        return;

    for (const auto &[nextCh, childNode] : node->children) {
        collectFuzzy(childNode.get(),
                     nextCh,
                     query,
                     currentWord + nextCh,
                     currentRow,
                     maxDist,
                     results);
    }
}

QStringList SuggestionEngine::suggest(const QString &prefix,
                                      const QString &prevWord,
                                      const QString &prevWord2,
                                      int maxResults,
                                      int maxEditDist) const
{
    QString lower = prefix.toLower().trimmed();

    const TrieNode *node = m_root.get();
    for (const QChar &ch : lower) {
        auto it = node->children.find(ch);
        if (it == node->children.end()) {
            node = nullptr;
            break;
        }
        node = it->second.get();
    }

    QList<WordEntry> candidates;
    if (node)
        collectSuggestions(node, lower, candidates);

    if (maxEditDist > 0 && candidates.size() < maxResults && !lower.isEmpty()) {
        std::vector<int> initialRow(lower.size() + 1);
        std::iota(initialRow.begin(), initialRow.end(), 0);

        for (const auto &[ch, childNode] : m_root->children) {
            collectFuzzy(childNode.get(),
                         ch,
                         lower,
                         QString(ch),
                         initialRow,
                         maxEditDist,
                         candidates);
        }

        std::sort(candidates.begin(), candidates.end(), [](const WordEntry &a, const WordEntry &b) {
            return a.editDistance < b.editDistance;
        });

        QSet<QString> seen;
        QList<WordEntry> deduped;
        deduped.reserve(candidates.size());
        for (const WordEntry &e : candidates) {
            if (!seen.contains(e.word)) {
                seen.insert(e.word);
                deduped.append(e);
            }
        }
        candidates = std::move(deduped);
    }

    if (!prevWord.isEmpty()) {
        QString prev = prevWord.toLower().trimmed();
        QString prev2 = prevWord2.toLower().trimmed();

        if (!prev2.isEmpty()) {
            auto t1 = m_trigrams.find(prev2);
            if (t1 != m_trigrams.end()) {
                auto t2 = t1.value().find(prev);
                if (t2 != t1.value().end()) {
                    const auto &follows = t2.value();
                    for (WordEntry &entry : candidates) {
                        auto it = follows.find(entry.word);
                        if (it != follows.end())
                            entry.frequency += it.value() * 20;
                    }
                }
            }
        }

        auto bigramIt = m_bigrams.find(prev);
        if (bigramIt != m_bigrams.end()) {
            const auto &follows = bigramIt.value();
            for (WordEntry &entry : candidates) {
                auto it = follows.find(entry.word);
                if (it != follows.end())
                    entry.frequency += it.value() * 10;
            }
        }
    }

    std::stable_sort(candidates.begin(),
                     candidates.end(),
                     [](const WordEntry &a, const WordEntry &b) {
                         if (a.editDistance != b.editDistance)
                             return a.editDistance < b.editDistance;
                         return a.frequency > b.frequency;
                     });

    QStringList results;
    results.reserve(maxResults);
    for (int i = 0; i < std::min(static_cast<int>(candidates.size()), maxResults); ++i)
        results.append(candidates.at(i).word);

    return results;
}