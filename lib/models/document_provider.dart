// lib/models/document_provider.dart
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'document_model.dart';
import '../services/extraction_service.dart';
import '../services/pdf_export_service.dart';
import '../algorithms/nlp_engine.dart';
import '../algorithms/response_engine.dart';

class DocumentProvider extends ChangeNotifier {
  final List<DocumentModel> _docs = [];
  DocumentModel? _active;
  bool _busy = false;
  String _busyMsg = '';
  String? _error;
  final List<Map<String, dynamic>> _chat = [];
  bool _chatLoading = false;

  List<DocumentModel> get docs => List.unmodifiable(_docs);
  DocumentModel? get active => _active;
  bool get busy => _busy;
  String get busyMsg => _busyMsg;
  String? get error => _error;
  List<Map<String, dynamic>> get chat => List.unmodifiable(_chat);
  bool get chatLoading => _chatLoading;

  Future<void> pickDocument() async {
    _error = null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf','xlsx','xls','csv','docx','doc','txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (f.path == null) throw Exception('Cannot access file path.');
      final ext = p.extension(f.name).replaceAll('.','').toLowerCase();
      final doc = DocumentModel(
        id: const Uuid().v4(), name: f.name, path: f.path!,
        ext: ext, sizeBytes: f.size, addedAt: DateTime.now(),
        status: DocStatus.extracting,
      );
      _docs.insert(0, doc);
      _active = doc;
      _chat.clear();
      notifyListeners();
      await _process(doc);
    } catch (e) {
      _error = e.toString();
      _setBusy(false, '');
      notifyListeners();
    }
  }

  Future<void> _process(DocumentModel doc) async {
    try {
      _setBusy(true, 'Reading document...');
      doc.status = DocStatus.extracting;
      notifyListeners();
      final raw = await ExtractionService.extract(doc.path, doc.ext);
      final limited = ExtractionService.safeLimit(raw);
      doc.rawText = limited;
      if (limited.trim().isEmpty) throw Exception('No readable text found.');
      _setBusy(true, 'Running AI analysis...');
      doc.status = DocStatus.analyzing;
      notifyListeners();
      final analysis = await compute(_runNLP, limited);
      doc.analysis = analysis;
      doc.status = DocStatus.done;
      _setBusy(false, '');
      notifyListeners();
    } catch (e) {
      doc.error = e.toString();
      doc.status = DocStatus.error;
      _error = e.toString();
      _setBusy(false, '');
      notifyListeners();
    }
  }

  static DocAnalysis _runNLP(String text) => NLPEngine.analyze(text);

  Future<String?> generateResponse({
    required ResponseType type,
    required String instructions,
    String senderName = '', String senderTitle = '',
    String recipientName = '', String subject = '',
  }) async {
    if (_active?.analysis == null) return null;
    try {
      _setBusy(true, 'Generating document...');
      final content = ResponseEngine.generate(
        analysis: _active!.analysis!, type: type,
        userInstructions: instructions,
        senderName: senderName.isEmpty ? 'Your Name' : senderName,
        senderTitle: senderTitle.isEmpty ? 'Your Title' : senderTitle,
        recipientName: recipientName.isEmpty ? 'Recipient' : recipientName,
        subject: subject,
      );
      final path = await PdfExportService.exportResponse(
        content: content, title: _typeLabel(type));
      _setBusy(false, '');
      return path;
    } catch (e) {
      _error = e.toString(); _setBusy(false, ''); return null;
    }
  }

  Future<String?> downloadSummary() async {
    if (_active?.analysis == null) return null;
    try {
      _setBusy(true, 'Creating PDF...');
      final path = await PdfExportService.exportSummary(
        analysis: _active!.analysis!, originalFileName: _active!.name);
      _setBusy(false, '');
      return path;
    } catch (e) {
      _error = e.toString(); _setBusy(false, ''); return null;
    }
  }

  Future<void> sendChat(String question) async {
    if (_active?.rawText == null) return;
    _chat.add({'role': 'user', 'text': question, 'time': DateTime.now()});
    _chatLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));
    final answer = _answer(question, _active!);
    _chat.add({'role': 'ai', 'text': answer, 'time': DateTime.now()});
    _chatLoading = false;
    notifyListeners();
  }

  String _answer(String q, DocumentModel doc) {
    if (doc.analysis == null) return 'Document not analyzed yet.';
    final a = doc.analysis!;
    final ql = q.toLowerCase();
    if (_has(ql, ['summary','about','what is','overview','explain','describe']))
      return '${a.shortSummary}\n\nDocument type: ${a.docCategory}.';
    if (_has(ql, ['key point','important','main point','highlight','critical']))
      return 'Key points:\n\n${a.keyPoints.asMap().entries.map((e) => '${e.key+1}. ${e.value}').join('\n')}';
    if (_has(ql, ['message','saying','conclude','conclusion','purpose','point']))
      return 'Main message:\n\n"${a.mainMessage}"';
    if (_has(ql, ['keyword','topic','theme','subject']))
      return 'Key themes:\n\n${a.keywords.map((k) => '• $k').join('\n')}';
    if (_has(ql, ['type','category','kind','document type']))
      return 'This is classified as: ${a.docCategory}';
    if (_has(ql, ['long','length','word','count','read time','reading']))
      return '${a.wordCount} words  •  ${a.readTime}\nReadability: ${a.readabilityScore.toStringAsFixed(0)}/100';
    if (_has(ql, ['highlight','quote','important line']))
      return 'Important highlighted lines:\n\n${a.highlights.map((h) => '"$h"').join('\n\n')}';
    // keyword search fallback
    final words = q.toLowerCase().split(' ')
        .where((w) => w.length > 3 && !NLPEngine.isStopword(w)).toList();
    if (words.isNotEmpty && doc.rawText != null) {
      final sents = doc.rawText!.split(RegExp(r'(?<=[.!?])\s+'));
      final hits = sents.where((s) => words.any((w) => s.toLowerCase().contains(w))).take(3).toList();
      if (hits.isNotEmpty) return 'Relevant passages:\n\n${hits.map((h) => '• ${h.trim()}').join('\n\n')}';
    }
    return 'This is a ${a.docCategory}.\n\nMain message: "${a.mainMessage}"\n\nTry asking: summary, key points, keywords, highlights, or reading time.';
  }

  bool _has(String q, List<String> w) => w.any((x) => q.contains(x));

  void setActive(DocumentModel doc) { _active = doc; _chat.clear(); notifyListeners(); }
  void removeDoc(String id) {
    _docs.removeWhere((d) => d.id == id);
    if (_active?.id == id) _active = _docs.isEmpty ? null : _docs.first;
    notifyListeners();
  }
  void clearError() { _error = null; notifyListeners(); }
  void _setBusy(bool v, String m) { _busy = v; _busyMsg = m; notifyListeners(); }

  String _typeLabel(ResponseType t) => {
    ResponseType.formalLetter: 'Formal_Letter',
    ResponseType.report: 'Report',
    ResponseType.email: 'Email',
    ResponseType.actionPlan: 'Action_Plan',
    ResponseType.executiveSummary: 'Executive_Summary',
    ResponseType.acknowledgement: 'Acknowledgement',
    ResponseType.inquiry: 'Inquiry',
    ResponseType.rejection: 'Rejection_Letter',
  }[t] ?? 'Response';
}
