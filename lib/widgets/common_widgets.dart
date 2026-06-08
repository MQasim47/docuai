// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/document_model.dart';

// ── Glowing card ──────────────────────────────────────────────────────────────
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color? glow;
  final EdgeInsetsGeometry? padding;
  final Color? bg;
  final double radius;

  const GlowCard({
    super.key, required this.child,
    this.glow, this.padding, this.bg, this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final c = glow ?? AppTheme.primary;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? AppTheme.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.10), blurRadius: 18),
          BoxShadow(color: c.withOpacity(0.04), blurRadius: 40, spreadRadius: 2),
        ],
      ),
      child: child,
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────
class GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient grad;
  final double? width;
  final bool loading;
  final double height;

  const GradBtn({
    super.key, required this.label,
    this.onTap, this.icon,
    this.grad = AppTheme.cyanGrad,
    this.width, this.loading = false, this.height = 52,
  });

  @override
  State<GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<GradBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 90.ms);
  late final Animation<double> _s =
      Tween(begin: 1.0, end: 0.95)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown:   (_) { if (active) _c.forward(); },
      onTapUp:     (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: ()  { _c.reverse(); },
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          height: widget.height, width: widget.width,
          decoration: BoxDecoration(
            gradient: active
                ? widget.grad
                : const LinearGradient(
                    colors: [Color(0xFF1E2D40), Color(0xFF131E2C)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.28),
                    blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.2)),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;
  const StatusBadge(
      {super.key, required this.label, required this.color, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (pulse)
          Container(
              width: 6, height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.4, 1.4),
                  duration: 700.ms),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4)),
      ]),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────
class Shimmer extends StatefulWidget {
  final double width, height, radius;
  const Shimmer(
      {super.key,
      this.width = double.infinity,
      this.height = 18,
      this.radius = 8});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 1300.ms)..repeat();
  late final Animation<double> _a = Tween(begin: -2.0, end: 2.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_a.value - 1, 0),
              end: Alignment(_a.value, 0),
              colors: [
                AppTheme.bgSurface,
                AppTheme.border,
                AppTheme.bgSurface
              ],
            ),
          ),
        ),
      );
}

// ── File type icon ────────────────────────────────────────────────────────────
class FileIcon extends StatelessWidget {
  final String ext;
  final double size;
  const FileIcon({super.key, required this.ext, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.forType(ext);
    final icon = _iconFor(ext);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: size * 0.50),
    );
  }

  IconData _iconFor(String e) {
    switch (e) {
      case 'pdf':  return Icons.picture_as_pdf_rounded;
      case 'xlsx':
      case 'xls':
      case 'csv':  return Icons.table_chart_rounded;
      case 'docx':
      case 'doc':  return Icons.description_rounded;
      default:     return Icons.text_snippet_rounded;
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const SectionHeader(
      {super.key,
      required this.icon,
      required this.color,
      required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                    color: AppTheme.textPri,
                    fontWeight: FontWeight.w600)),
      ]);
}
