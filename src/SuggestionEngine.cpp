#include "SuggestionEngine.h"

#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>

SuggestionEngine::SuggestionEngine()
    : m_root(std::make_unique<TrieNode>()) {}

void SuggestionEngine::insert(const QString &word, uint32_t frequency) {
    if (word.isEmpty()) return;

    TrieNode *node = m_root.get();
    for (const QChar &ch : word) {
        QChar lower = ch.toLower();
        auto it = node->children.find(lower);
        if (it == node->children.end()) {
            auto result = node->children.emplace(lower, std::make_unique<TrieNode>());
            node = result.first->second.get();
        } else {
            node = it->second.get();
        }
    }
    node->isTerminal = true;
    node->frequency = std::max(node->frequency, frequency);
}

void SuggestionEngine::loadDictionary(const QString &path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty()) continue;

        QStringList parts = line.split('\t');
        QString word = parts.at(0).toLower();
        uint32_t freq = (parts.size() > 1) ? parts.at(1).toUInt() : 1;

        if (!word.isEmpty()) insert(word, freq);
    }
}

void SuggestionEngine::loadUserData(const QString &path) {
    m_userDataPath = path;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        insert(it.key(), static_cast<uint32_t>(it.value().toInt()));
    }
}

void SuggestionEngine::saveUserData(const QString &path) const {
    QJsonObject obj;
    QList<WordEntry> all;
    collectSuggestions(m_root.get(), QString(), all);

    for (const WordEntry &entry : all) {
        obj.insert(entry.word, static_cast<int>(entry.frequency));
    }

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) return;
    file.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

void SuggestionEngine::learnWord(const QString &word) {
    QString lower = word.toLower().trimmed();
    if (lower.isEmpty() || lower.size() < 2) return;

    TrieNode *node = m_root.get();
    for (const QChar &ch : lower) {
        auto it = node->children.find(ch);
        if (it == node->children.end()) {
            auto result = node->children.emplace(ch, std::make_unique<TrieNode>());
            node = result.first->second.get();
        } else {
            node = it->second.get();
        }
    }
    node->isTerminal = true;
    node->frequency += 1;

    if (!m_userDataPath.isEmpty()) {
        saveUserData(m_userDataPath);
    }
}

void SuggestionEngine::collectSuggestions(const TrieNode *node, const QString &prefix,
                                          QList<WordEntry> &results) const {
    if (!node) return;

    if (node->isTerminal) {
        results.append({prefix, node->frequency});
    }

    for (const auto &[ch, child] : node->children) {
        collectSuggestions(child.get(), prefix + ch, results);
    }
}

QStringList SuggestionEngine::suggest(const QString &prefix, int maxResults) const {
    QString lower = prefix.toLower().trimmed();

    const TrieNode *node = m_root.get();
    for (const QChar &ch : lower) {
        auto it = node->children.find(ch);
        if (it == node->children.end()) return {};
        node = it->second.get();
    }

    QList<WordEntry> candidates;
    collectSuggestions(node, lower, candidates);

    std::sort(candidates.begin(), candidates.end(), [](const WordEntry &a, const WordEntry &b) {
        return a.frequency > b.frequency;
    });

    QStringList results;
    for (int i = 0; i < std::min(static_cast<int>(candidates.size()), maxResults); ++i) {
        results.append(candidates.at(i).word);
    }
    return results;
}