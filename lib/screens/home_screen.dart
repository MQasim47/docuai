// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../models/document_model.dart';
import '../models/document_provider.dart';
import '../widgets/common_widgets.dart';
import 'analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _appBar(context)),
            SliverToBoxAdapter(child: _uploadZone(context)),
            SliverToBoxAdapter(child: _statsRow(context)),
            SliverToBoxAdapter(child: _sectionTitle(context)),
            _docList(context),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: AppTheme.cyanGrad,
            borderRadius: BorderRadius.circular(13),
            boxShadow: AppTheme.cyanGlow,
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (r) => AppTheme.cyanGrad.createShader(r),
            child: Text('DocuAI',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: Colors.white)),
          ),
          Text('Document Intelligence',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  letterSpacing: 1)),
        ]),
        const Spacer(),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(Icons.info_outline_rounded,
              color: AppTheme.textSec, size: 20),
        ),
      ]).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  // ── Upload zone ───────────────────────────────────────────────────────────
  Widget _uploadZone(BuildContext context) {
    final p = context.watch<DocumentProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analyze a Document',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('PDF • Excel • Word • TXT — 100% offline',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSec)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: p.busy ? null : p.pickDocument,
          child: DottedBorder(
            color: AppTheme.primary.withOpacity(0.45),
            strokeWidth: 1.5,
            dashPattern: const [8, 5],
            borderType: BorderType.RRect,
            radius: const Radius.circular(20),
            child: Container(
              height: 155,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: p.busy ? _busyState(context, p) : _idleState(context),
            ),
          ),
        ),
        // Error snackbar-style
        if (p.error != null)
          GestureDetector(
            onTap: p.clearError,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded,
                    color: AppTheme.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(p.error!,
                        style: TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12))),
                Icon(Icons.close_rounded,
                    color: AppTheme.danger, size: 14),
              ]),
            ),
          ),
      ]).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),
    );
  }

  Widget _idleState(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.cyanGrad,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cyanGlow,
            ),
            child: const Icon(Icons.upload_rounded,
                color: Colors.white, size: 26),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 1800.ms,
                  curve: Curves.easeInOut),
          const SizedBox(height: 14),
          Text('Tap to upload document',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('No internet needed • No API key • Free forever',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted, fontSize: 11)),
        ]),
      );

  Widget _busyState(BuildContext context, DocumentProvider p) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 46, height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.busyMsg,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 6),
          Text('Powered by built-in NLP engine',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted, fontSize: 11)),
        ]),
      );

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _statsRow(BuildContext context) {
    final docs = context.watch<DocumentProvider>().docs;
    final done = docs.where((d) => d.status == DocStatus.done).length;
    final thisMonth = docs
        .where((d) => d.addedAt.month == DateTime.now().month)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(children: [
        _StatTile(icon: Icons.folder_rounded,
            color: AppTheme.primary, label: 'Total', value: '${docs.length}'),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.check_circle_rounded,
            color: AppTheme.success, label: 'Analyzed', value: '$done'),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.calendar_today_rounded,
            color: AppTheme.accent, label: 'This month', value: '$thisMonth'),
      ]).animate().fadeIn(delay: 300.ms),
    );
  }

  Widget _sectionTitle(BuildContext context) {
    final count = context.watch<DocumentProvider>().docs.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Documents',
                style: Theme.of(context).textTheme.headlineMedium),
            if (count > 0)
              Text('$count file${count > 1 ? 's' : ''}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.primary)),
          ]),
    );
  }

  // ── Document list ─────────────────────────────────────────────────────────
  SliverList _docList(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final docs = context.watch<DocumentProvider>().docs;
          if (docs.isEmpty) return _empty(context);
          final doc = docs[index];
          return _DocCard(
            doc: doc,
            onTap: () {
              context.read<DocumentProvider>().setActive(doc);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a, __) => const AnalysisScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween(
                            begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: 320.ms,
                ),
              );
            },
            onDelete: () =>
                context.read<DocumentProvider>().removeDoc(doc.id),
          ).animate().fadeIn(delay: (index * 70).ms).slideX(begin: 0.1, end: 0);
        },
        childCount: context.watch<DocumentProvider>().docs.isEmpty
            ? 1
            : context.watch<DocumentProvider>().docs.length,
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(children: [
          Icon(Icons.inbox_rounded, size: 60, color: AppTheme.textMuted),
          const SizedBox(height: 14),
          Text('No documents yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text('Upload your first document above',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
}

// ── Stat tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _StatTile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 9),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10)),
          ]),
        ),
      );
}

// ── Document card ─────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final DocumentModel doc;
  final VoidCallback onTap, onDelete;
  const _DocCard(
      {required this.doc, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final canTap = doc.status == DocStatus.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTap: canTap ? onTap : null,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor(), width: 1),
          ),
          child: Row(children: [
            FileIcon(ext: doc.ext),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.sizeLabel}  •  ${doc.typeLabel}',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    _badge(),
                  ]),
            ),
            if (doc.status == DocStatus.analyzing ||
                doc.status == DocStatus.extracting)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary),
                ),
              ),
            if (canTap)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary, size: 22),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close_rounded,
                    color: AppTheme.textMuted, size: 17),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Color _borderColor() {
    switch (doc.status) {
      case DocStatus.done:      return AppTheme.border;
      case DocStatus.analyzing:
      case DocStatus.extracting: return AppTheme.primary.withOpacity(0.35);
      case DocStatus.error:     return AppTheme.danger.withOpacity(0.4);
      default:                  return AppTheme.border;
    }
  }

  Widget _badge() {
    switch (doc.status) {
      case DocStatus.done:
        return const StatusBadge(label: 'Analyzed', color: AppTheme.success);
      case DocStatus.extracting:
        return const StatusBadge(
            label: 'Extracting…', color: AppTheme.primary, pulse: true);
      case DocStatus.analyzing:
        return const StatusBadge(
            label: 'Analyzing…', color: AppTheme.accent, pulse: true);
      case DocStatus.error:
        return StatusBadge(
            label: doc.error ?? 'Error', color: AppTheme.danger);
      default:
        return const StatusBadge(label: 'Pending', color: AppTheme.textSec);
    }
  }
}
