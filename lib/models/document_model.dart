// lib/models/document_model.dart

enum DocStatus { idle, extracting, analyzing, done, error }

class DocumentModel {
  final String id;
  final String name;
  final String path;
  final String ext;        // pdf, xlsx, docx, txt …
  final int sizeBytes;
  final DateTime addedAt;
  DocStatus status;
  String? rawText;
  DocAnalysis? analysis;
  String? error;

  DocumentModel({
    required this.id,
    required this.name,
    required this.path,
    required this.ext,
    required this.sizeBytes,
    required this.addedAt,
    this.status = DocStatus.idle,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes/1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes/1048576).toStringAsFixed(1)} MB';
  }

  String get typeLabel => ext.toUpperCase();
}

// ─── Analysis result produced by our free NLP engine ─────────────────────────
class DocAnalysis {
  final String shortSummary;       // 2-3 sentences
  final String fullSummary;        // full paragraph
  final List<String> keyPoints;    // top 5 bullet points
  final List<String> highlights;   // most important individual lines
  final String mainMessage;        // one-line "what does this doc say"
  final String docCategory;        // Contract / Report / Letter / Invoice …
  final List<String> keywords;     // top 10 keywords
  final int wordCount;
  final String readTime;
  final double readabilityScore;   // 0-100

  DocAnalysis({
    required this.shortSummary,
    required this.fullSummary,
    required this.keyPoints,
    required this.highlights,
    required this.mainMessage,
    required this.docCategory,
    required this.keywords,
    required this.wordCount,
    required this.readTime,
    required this.readabilityScore,
  });
}
