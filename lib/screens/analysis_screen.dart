// lib/screens/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import '../theme/app_theme.dart';
import '../models/document_model.dart';
import '../models/document_provider.dart';
import '../widgets/common_widgets.dart';
import 'response_screen.dart';
import 'chat_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  bool _downloading = false;

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doc = context.watch<DocumentProvider>().active;
    if (doc == null) {
      return const Scaffold(
          backgroundColor: AppTheme.bg,
          body: Center(child: Text('No document')));
    }
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          _header(context, doc),
          if (doc.analysis != null) _mainMessage(context, doc.analysis!),
          _tabBar(),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _SummaryTab(doc: doc),
              _KeyPointsTab(doc: doc),
              const ChatScreen(),
            ]),
          ),
          if (doc.status == DocStatus.done) _actionBar(context),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context, DocumentModel doc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textSec, size: 16),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${doc.sizeLabel}  •  ${doc.analysis?.docCategory ?? doc.typeLabel}',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
          ]),
        ),
        FileIcon(ext: doc.ext, size: 42),
      ]).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _mainMessage(BuildContext context, DocAnalysis a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GlowCard(
        glow: AppTheme.accent,
        padding: const EdgeInsets.all(13),
        bg: AppTheme.accent.withOpacity(0.07),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGrad,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Main Message',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 3),
                  Text(a.mainMessage,
                      style: const TextStyle(
                          color: AppTheme.textPri,
                          fontSize: 12,
                          height: 1.4)),
                ]),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.border),
        ),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            gradient: AppTheme.cyanGrad,
            borderRadius: BorderRadius.circular(9),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSec,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Key Points'),
            Tab(text: 'Chat'),
          ],
        ),
      );

  // ── Action bar ────────────────────────────────────────────────────────────
  Widget _actionBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(children: [
          Expanded(
            child: GradBtn(
              label: 'Create Response',
              icon: Icons.edit_rounded,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ResponseScreen())),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _downloading ? null : _download,
            child: AnimatedContainer(
              duration: 200.ms,
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: _downloading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded,
                      color: AppTheme.textSec, size: 22),
            ),
          ),
        ]),
      ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn();

  Future<void> _download() async {
    setState(() => _downloading = true);
    final path = await context.read<DocumentProvider>().downloadSummary();
    if (path != null && mounted) {
      await OpenFile.open(path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Summary PDF saved!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
    if (mounted) setState(() => _downloading = false);
  }
}

// ── Summary tab ───────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final DocumentModel doc;
  const _SummaryTab({required this.doc});

  @override
  Widget build(BuildContext context) {
    if (doc.analysis == null) return _skeletons();
    final a = doc.analysis!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        // Metrics row
        Row(children: [
          _Metric(icon: Icons.text_fields_rounded,
              label: 'Words', value: '${a.wordCount}'),
          const SizedBox(width: 8),
          _Metric(icon: Icons.timer_outlined,
              label: 'Read time', value: a.readTime),
          const SizedBox(width: 8),
          _Metric(
              icon: Icons.speed_rounded,
              label: 'Readability',
              value: '${a.readabilityScore.toStringAsFixed(0)}/100'),
        ]).animate().fadeIn(),
        const SizedBox(height: 14),
        // Summary card
        GlowCard(
          glow: AppTheme.primary,
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                    icon: Icons.summarize_rounded,
                    color: AppTheme.primary,
                    title: 'Summary'),
                const SizedBox(height: 12),
                Text(a.fullSummary,
                    style: const TextStyle(
                        color: AppTheme.textSec,
                        height: 1.65,
                        fontSize: 14)),
              ]),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 14),
        // Highlights card
        GlowCard(
          glow: AppTheme.accent,
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                    icon: Icons.format_quote_rounded,
                    color: AppTheme.accent,
                    title: 'Important Highlights'),
                const SizedBox(height: 12),
                ...a.highlights
                    .asMap()
                    .entries
                    .map((e) => _HighlightTile(
                        text: e.value, index: e.key)),
              ]),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 14),
        // Keywords
        GlowCard(
          glow: AppTheme.purple,
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                    icon: Icons.tag_rounded,
                    color: AppTheme.purple,
                    title: 'Keywords'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: a.keywords
                      .map((k) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.purple.withOpacity(0.3)),
                            ),
                            child: Text(k,
                                style: const TextStyle(
                                    color: AppTheme.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ]),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _skeletons() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Shimmer(height: 60, radius: 14),
          const SizedBox(height: 12),
          const Shimmer(height: 160, radius: 16),
          const SizedBox(height: 12),
          const Shimmer(height: 130, radius: 16),
        ],
      );
}

// ── Highlight tile ────────────────────────────────────────────────────────────
class _HighlightTile extends StatelessWidget {
  final String text;
  final int index;
  const _HighlightTile({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Copied!'),
          backgroundColor: AppTheme.success,
          duration: 1500.ms,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22, height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGrad,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textPri,
                    fontSize: 13,
                    height: 1.5)),
          ),
        ]),
      ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: -0.08, end: 0),
    );
  }
}

// ── Key Points tab ────────────────────────────────────────────────────────────
class _KeyPointsTab extends StatelessWidget {
  final DocumentModel doc;
  const _KeyPointsTab({required this.doc});

  static const _colors = [
    AppTheme.primary, AppTheme.accent, AppTheme.success,
    AppTheme.purple, Color(0xFFFF7744),
  ];

  @override
  Widget build(BuildContext context) {
    if (doc.analysis == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
            5,
            (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer(height: 76, radius: 14))),
      );
    }
    final points = doc.analysis!.keyPoints;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: points.length,
      itemBuilder: (_, i) {
        final color = _colors[i % _colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(points[i],
                  style: const TextStyle(
                      color: AppTheme.textSec,
                      height: 1.55,
                      fontSize: 14)),
            ),
          ]),
        ).animate().fadeIn(delay: (i * 90).ms).slideX(begin: 0.15, end: 0);
      },
    );
  }
}

// ── Metric chip ───────────────────────────────────────────────────────────────
class _Metric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Metric(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Icon(icon, color: AppTheme.primary, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            color: AppTheme.textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(label,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 9)),
                  ]),
            ),
          ]),
        ),
      );
}
