// lib/algorithms/nlp_engine.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║   DocuAI  —  Custom NLP Engine                               ║
// ║   Algorithm: TF-IDF  +  TextRank  +  Keyword Extraction      ║
// ║   Cost: $0.00  |  Offline: YES  |  No API: YES               ║
// ╚══════════════════════════════════════════════════════════════╝
//
// How it works:
//  1. Tokenise text into sentences and words
//  2. Remove stopwords (common words like "the", "is", "and")
//  3. TF-IDF: score each word by how unique it is to this document
//  4. Score each sentence by the TF-IDF weight of its words
//  5. TextRank: build a similarity graph between sentences,
//     run PageRank-style iterations → best sentences bubble up
//  6. Pick top sentences for summary, key points, highlights
//  7. Classify document type from keyword patterns

import 'dart:math' as math;
import '../models/document_model.dart';

class NLPEngine {
  // ── Public entry point ────────────────────────────────────────────────────
  static DocAnalysis analyze(String text) {
    if (text.trim().isEmpty) {
      return _empty();
    }

    final sentences  = _tokenizeSentences(text);
    final words      = _tokenizeWords(text);
    final filtered   = words.map(_stem).where((w) => !_stopwords.contains(w) && w.length > 2).toList();

    final tfidf      = _computeTFIDF(sentences, filtered);
    final scores     = _textRank(sentences, tfidf);

    // Sort sentences by score (keep original order for readability)
    final ranked = List.generate(sentences.length, (i) => _Scored(i, scores[i]))
      ..sort((a, b) => b.score.compareTo(a.score));

    final keywords   = _extractKeywords(filtered, tfidf);
    final category   = _classifyDocument(keywords, text);
    final wordCount  = words.length;
    final readTime   = '${(wordCount / 200).ceil()} min read';

    // ── Build outputs ─────────────────────────────────────────────────────
    // Short summary: top 2-3 sentences, restored to original order
    final topIdx = ranked.take(3).map((s) => s.index).toList()..sort();
    final shortSummary = topIdx.map((i) => sentences[i]).join(' ');

    // Full summary: top 5 sentences in original order
    final fullIdx = ranked.take(5).map((s) => s.index).toList()..sort();
    final fullSummary = fullIdx.map((i) => sentences[i]).join(' ');

    // Key points: next 5 highest-ranked sentences (sentences 4-8)
    final kpIdx = ranked.skip(3).take(5).map((s) => s.index).toList()..sort();
    final keyPoints = kpIdx.map((i) => _cleanSentence(sentences[i])).toList();

    // Highlights: top 3 sentences (these are the very best)
    final highlights = ranked.take(3)
        .map((s) => _cleanSentence(sentences[s.index]))
        .toList();

    // Main message: single best sentence
    final mainMessage = sentences.isNotEmpty
        ? _cleanSentence(sentences[ranked.first.index])
        : 'Unable to determine main message.';

    // Readability (Flesch-Kincaid approximation)
    final readability = _readabilityScore(text, words, sentences);

    return DocAnalysis(
      shortSummary: shortSummary.isEmpty ? 'Could not extract summary.' : shortSummary,
      fullSummary: fullSummary.isEmpty ? shortSummary : fullSummary,
      keyPoints: keyPoints.isEmpty ? ['No key points found.'] : keyPoints,
      highlights: highlights.isEmpty ? [mainMessage] : highlights,
      mainMessage: mainMessage,
      docCategory: category,
      keywords: keywords,
      wordCount: wordCount,
      readTime: readTime,
      readabilityScore: readability,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — TOKENISATION
  // ══════════════════════════════════════════════════════════════════════════

  static List<String> _tokenizeSentences(String text) {
    // Split on sentence-ending punctuation followed by space/newline
    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'--- Page \d+ ---'), '')
        .trim();

    final raw = cleaned.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])'));

    return raw
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 5)  // skip very short fragments
        .take(200)                                 // cap for performance
        .toList();
  }

  static List<String> _tokenizeWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — STEMMING (simple suffix stripping)
  // ══════════════════════════════════════════════════════════════════════════

  static String _stem(String word) {
    // Very lightweight Porter-style stemming
    if (word.length <= 3) return word;
    if (word.endsWith('ing'))  return word.substring(0, word.length - 3);
    if (word.endsWith('tion')) return word.substring(0, word.length - 4);
    if (word.endsWith('ness')) return word.substring(0, word.length - 4);
    if (word.endsWith('ment')) return word.substring(0, word.length - 4);
    if (word.endsWith('ies'))  return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('es') && word.length > 4) return word.substring(0, word.length - 2);
    if (word.endsWith('ed') && word.length > 4) return word.substring(0, word.length - 2);
    if (word.endsWith('ly') && word.length > 4) return word.substring(0, word.length - 2);
    if (word.endsWith('er') && word.length > 4) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && word.length > 3)  return word.substring(0, word.length - 1);
    return word;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — TF-IDF COMPUTATION
  // ══════════════════════════════════════════════════════════════════════════

  // TF-IDF: words that appear often in THIS doc but rarely in general text
  // are considered more important.
  //
  // TF  = count of word in doc / total words in doc
  // IDF = log(total sentences / sentences containing word)
  // TF-IDF = TF * IDF

  static Map<String, double> _computeTFIDF(
      List<String> sentences, List<String> filteredWords) {
    // Term Frequency
    final tf = <String, int>{};
    for (final w in filteredWords) {
      tf[w] = (tf[w] ?? 0) + 1;
    }

    // Document Frequency (how many sentences contain each word)
    final df = <String, int>{};
    for (final sentence in sentences) {
      final sentWords = _tokenizeWords(sentence).map(_stem).toSet();
      for (final w in sentWords) {
        if (tf.containsKey(w)) df[w] = (df[w] ?? 0) + 1;
      }
    }

    final n = sentences.length.toDouble().clamp(1, double.infinity);
    final scores = <String, double>{};

    tf.forEach((word, count) {
      final termFreq = count / filteredWords.length.clamp(1, 9999999);
      final docFreq  = (df[word] ?? 1).toDouble();
      final idf      = math.log(n / docFreq) + 1;
      scores[word]   = termFreq * idf;
    });

    return scores;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 — TEXTRANK (Sentence-level PageRank)
  // ══════════════════════════════════════════════════════════════════════════

  // Build a similarity matrix between sentences.
  // Two sentences are similar if they share important (high TF-IDF) words.
  // Run power-iteration (like Google PageRank) to find the most central sentences.

  static List<double> _textRank(
      List<String> sentences, Map<String, double> tfidf) {
    final n = sentences.length;
    if (n == 0) return [];
    if (n == 1) return [1.0];

    // Represent each sentence as a TF-IDF vector
    final vectors = sentences.map((s) {
      final words = _tokenizeWords(s).map(_stem).toSet();
      final vec = <String, double>{};
      for (final w in words) {
        if (tfidf.containsKey(w)) vec[w] = tfidf[w]!;
      }
      return vec;
    }).toList();

    // Similarity: cosine similarity between two TF-IDF vectors
    double cosine(Map<String, double> a, Map<String, double> b) {
      double dot = 0, normA = 0, normB = 0;
      for (final k in a.keys) {
        dot   += a[k]! * (b[k] ?? 0);
        normA += a[k]! * a[k]!;
      }
      for (final v in b.values) normB += v * v;
      final denom = math.sqrt(normA) * math.sqrt(normB);
      return denom == 0 ? 0 : dot / denom;
    }

    // Build similarity matrix
    final sim = List.generate(n, (i) =>
        List.generate(n, (j) => i == j ? 0.0 : cosine(vectors[i], vectors[j])));

    // Normalize each row
    for (int i = 0; i < n; i++) {
      final rowSum = sim[i].fold(0.0, (a, b) => a + b);
      if (rowSum > 0) {
        for (int j = 0; j < n; j++) sim[i][j] /= rowSum;
      }
    }

    // Power iteration (damping factor d=0.85, as in original PageRank)
    const d = 0.85;
    var scores = List.filled(n, 1.0 / n);

    for (int iter = 0; iter < 30; iter++) {
      final newScores = List.filled(n, (1 - d) / n);
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          newScores[i] += d * sim[j][i] * scores[j];
        }
      }
      scores = newScores;
    }

    return scores;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 5 — KEYWORD EXTRACTION
  // ══════════════════════════════════════════════════════════════════════════

  static List<String> _extractKeywords(
      List<String> words, Map<String, double> tfidf) {
    final sorted = tfidf.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(12)
        .map((e) => e.key)
        .where((k) => k.length > 3)
        .take(10)
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 6 — DOCUMENT CLASSIFICATION
  // ══════════════════════════════════════════════════════════════════════════

  static String _classifyDocument(List<String> keywords, String text) {
    final lower = text.toLowerCase();

    final patterns = <String, List<String>>{
      'Legal Contract':      ['agreement', 'party', 'clause', 'terms', 'conditions', 'hereby', 'shall', 'obligation', 'liability'],
      'Financial Report':    ['revenue', 'profit', 'loss', 'balance', 'financial', 'fiscal', 'quarter', 'earnings', 'expenses', 'budget'],
      'Research Paper':      ['abstract', 'methodology', 'hypothesis', 'conclusion', 'references', 'study', 'analysis', 'findings', 'literature'],
      'Business Proposal':   ['proposal', 'objective', 'solution', 'deliverable', 'timeline', 'budget', 'scope', 'client', 'project'],
      'Invoice / Receipt':   ['invoice', 'amount', 'total', 'payment', 'due', 'billing', 'receipt', 'tax', 'subtotal'],
      'HR / Resume':         ['experience', 'skills', 'education', 'employment', 'position', 'responsibilities', 'qualification', 'candidate'],
      'Medical Report':      ['patient', 'diagnosis', 'treatment', 'symptoms', 'prescription', 'clinical', 'medical', 'dosage', 'doctor'],
      'Academic Document':   ['chapter', 'thesis', 'university', 'professor', 'course', 'semester', 'grade', 'exam', 'assignment'],
      'News / Article':      ['reported', 'according', 'sources', 'statement', 'announced', 'official', 'government', 'said'],
      'Email / Letter':      ['dear', 'sincerely', 'regards', 'subject', 'attached', 'kindly', 'please', 'thank you'],
      'Technical Manual':    ['installation', 'configuration', 'specification', 'procedure', 'system', 'module', 'version', 'step'],
    };

    int bestScore = 0;
    String bestCategory = 'General Document';

    patterns.forEach((category, words) {
      int score = 0;
      for (final w in words) {
        if (lower.contains(w)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 7 — READABILITY SCORE (Flesch approximation)
  // ══════════════════════════════════════════════════════════════════════════

  static double _readabilityScore(
      String text, List<String> words, List<String> sentences) {
    if (words.isEmpty || sentences.isEmpty) return 50;

    final avgWordsPerSentence = words.length / sentences.length;

    // Estimate syllables: count vowel groups per word
    int totalSyllables = 0;
    for (final w in words) {
      totalSyllables += _syllables(w);
    }
    final avgSyllablesPerWord = totalSyllables / words.length;

    // Flesch Reading Ease formula
    final score = 206.835
        - (1.015 * avgWordsPerSentence)
        - (84.6  * avgSyllablesPerWord);

    return score.clamp(0, 100);
  }

  static int _syllables(String word) {
    final vowels = RegExp(r'[aeiou]+', caseSensitive: false);
    return vowels.allMatches(word).length.clamp(1, 10);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  /// Public: used by DocumentProvider for chat keyword filtering
  static bool isStopword(String word) => _stopwords.contains(word.toLowerCase());

  static String _cleanSentence(String s) {
    return s.trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[-–—•*\d.]+\s*'), '');
  }

  static DocAnalysis _empty() => DocAnalysis(
    shortSummary: 'No readable text found in this document.',
    fullSummary: 'The document appears to be empty or contains only images.',
    keyPoints: ['Ensure the document contains readable text.'],
    highlights: ['No highlights available.'],
    mainMessage: 'Document could not be analyzed.',
    docCategory: 'Unknown',
    keywords: [],
    wordCount: 0,
    readTime: '0 min',
    readabilityScore: 0,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // STOPWORDS — words to IGNORE (they carry no meaning)
  // ══════════════════════════════════════════════════════════════════════════

  static const Set<String> _stopwords = {
    'a','an','the','and','or','but','in','on','at','to','for','of','with',
    'by','from','is','are','was','were','be','been','being','have','has',
    'had','do','does','did','will','would','could','should','may','might',
    'shall','can','need','dare','used','ought','it','its','this','that',
    'these','those','i','me','my','we','us','our','you','your','he','him',
    'his','she','her','they','them','their','what','which','who','whom',
    'whose','when','where','why','how','all','any','both','each','few',
    'more','most','other','some','such','no','not','only','same','so',
    'than','too','very','just','as','if','about','above','after','again',
    'also','among','because','before','between','during','here','into',
    'never','now','own','per','since','then','there','through','under',
    'until','up','upon','while','within','without','yet','however','thus',
    'hence','therefore','moreover','furthermore','accordingly','although',
    'though','whereas','whether','unless','even','much','many','still',
    'already','always','often','usually','generally','recently','currently',
    'including','regarding','following','according','based','made','make',
    'use','using','provide','provided','provides','get','set','new',
  };
}

// ── Internal helper ────────────────────────────────────────────────────────
class _Scored {
  final int index;
  final double score;
  _Scored(this.index, this.score);
}