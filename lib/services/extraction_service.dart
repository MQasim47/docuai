// lib/services/extraction_service.dart
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:docx_to_text/docx_to_text.dart';

class ExtractionService {
  static Future<String> extract(String path, String ext) async {
    switch (ext.toLowerCase()) {
      case 'pdf':  return _pdf(path);
      case 'xlsx':
      case 'xls':  return _excel(path);
      case 'csv':  return _txt(path);
      case 'docx':
      case 'doc':  return _docx(path);
      default:     return _txt(path);
    }
  }

  static Future<String> _pdf(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final doc   = PdfDocument(inputBytes: bytes);
      final ext   = PdfTextExtractor(doc);
      final buf   = StringBuffer();
      for (int i = 0; i < doc.pages.count; i++) {
        final t = ext.extractText(startPageIndex: i, endPageIndex: i);
        if (t.trim().isNotEmpty) { buf.writeln('--- Page ${i+1} ---'); buf.writeln(t.trim()); buf.writeln(); }
      }
      doc.dispose();
      final r = buf.toString().trim();
      if (r.isEmpty) throw Exception('PDF has no extractable text (may be scanned/image-only).');
      return r;
    } catch (e) { throw Exception('PDF read error: $e'); }
  }

  static Future<String> _excel(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final book  = Excel.decodeBytes(bytes);
      final buf   = StringBuffer();
      for (final s in book.tables.keys) {
        final sheet = book.tables[s]!;
        if (sheet.rows.isEmpty) continue;
        buf.writeln('=== Sheet: $s ===');
        for (final row in sheet.rows) {
          final cells = row.map((c) => c?.value?.toString().trim() ?? '').where((v) => v.isNotEmpty).join(' | ');
          if (cells.isNotEmpty) buf.writeln(cells);
        }
        buf.writeln();
      }
      return buf.toString().trim();
    } catch (e) { throw Exception('Excel read error: $e'); }
  }

  static Future<String> _docx(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      return docxToText(bytes).trim();
    } catch (e) {
      try { return await _txt(path); } catch (_) {}
      throw Exception('DOCX read error: $e');
    }
  }

  static Future<String> _txt(String path) async {
    try { return (await File(path).readAsString()).trim(); }
    catch (e) { throw Exception('Text read error: $e'); }
  }

  static String safeLimit(String text, {int max = 40000}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}\n\n[Document truncated — first ${max ~/ 1000}k chars shown]';
  }
}
