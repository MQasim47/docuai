// lib/screens/response_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import '../theme/app_theme.dart';
import '../algorithms/response_engine.dart';
import '../models/document_provider.dart';
import '../widgets/common_widgets.dart';

class ResponseScreen extends StatefulWidget {
  const ResponseScreen({super.key});
  @override
  State<ResponseScreen> createState() => _ResponseScreenState();
}

class _ResponseScreenState extends State<ResponseScreen> {
  ResponseType _type = ResponseType.formalLetter;
  final _instCtrl   = TextEditingController();
  final _senderCtrl = TextEditingController();
  final _titleCtrl  = TextEditingController();
  final _recpCtrl   = TextEditingController();
  final _subjCtrl   = TextEditingController();
  bool   _generating = false;
  String? _outputPath;

  static const _types = [
    (ResponseType.formalLetter,    'Formal Letter',     Icons.mail_rounded,        AppTheme.primary),
    (ResponseType.report,          'Report',            Icons.assessment_rounded,  AppTheme.success),
    (ResponseType.email,           'Email',             Icons.email_rounded,       AppTheme.accent),
    (ResponseType.actionPlan,      'Action Plan',       Icons.checklist_rounded,   AppTheme.purple),
    (ResponseType.executiveSummary,'Exec. Summary',     Icons.summarize_rounded,   Color(0xFFFF7744)),
    (ResponseType.acknowledgement, 'Acknowledgement',   Icons.thumb_up_rounded,    Color(0xFF44DDBB)),
    (ResponseType.inquiry,         'Inquiry',           Icons.help_rounded,        Color(0xFFBBAAFF)),
    (ResponseType.rejection,       'Rejection Letter',  Icons.cancel_rounded,      AppTheme.danger),
  ];

  @override
  void dispose() {
    _instCtrl.dispose(); _senderCtrl.dispose();
    _titleCtrl.dispose(); _recpCtrl.dispose(); _subjCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_instCtrl.text.trim().isEmpty) {
      _snack('Please add instructions for your response', AppTheme.danger);
      return;
    }
    setState(() => _generating = true);
    final path = await context.read<DocumentProvider>().generateResponse(
      type:          _type,
      instructions:  _instCtrl.text.trim(),
      senderName:    _senderCtrl.text.trim(),
      senderTitle:   _titleCtrl.text.trim(),
      recipientName: _recpCtrl.text.trim(),
      subject:       _subjCtrl.text.trim(),
    );
    if (mounted) {
      setState(() { _generating = false; _outputPath = path; });
      if (path != null) _snack('Document created!', AppTheme.success);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _label(context, 'Response Type'),
                const SizedBox(height: 12),
                _typeGrid(),
                const SizedBox(height: 20),
                _label(context, 'Sender Details (optional)'),
                const SizedBox(height: 10),
                _row([
                  _field(_senderCtrl, 'Your name'),
                  const SizedBox(width: 10),
                  _field(_titleCtrl, 'Your title'),
                ]),
                const SizedBox(height: 10),
                _row([
                  _field(_recpCtrl, 'Recipient name'),
                  const SizedBox(width: 10),
                  _field(_subjCtrl, 'Subject (optional)'),
                ]),
                const SizedBox(height: 20),
                _label(context, 'Instructions *'),
                const SizedBox(height: 10),
                GlowCard(
                  padding: EdgeInsets.zero,
                  child: TextField(
                    controller: _instCtrl,
                    style: const TextStyle(
                        color: AppTheme.textPri, fontSize: 14),
                    maxLines: 5, minLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. "Write a polite decline, mention budget constraints, suggest we revisit next quarter"',
                      hintStyle: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          height: 1.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Quick prompts
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    'Polite decline',
                    'Request more info',
                    'Approve with conditions',
                    'Formal acknowledgement',
                    'Urgent response',
                  ]
                      .map((s) => GestureDetector(
                            onTap: () => _instCtrl.text = s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppTheme.textSec,
                                      fontSize: 12)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 28),
                if (_outputPath != null) _successCard() else _generateBtn(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create Response',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('Free template engine — no API',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ]),
        ]).animate().fadeIn(),
      );

  Widget _label(BuildContext context, String t) => Text(t,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: AppTheme.textSec));

  Widget _typeGrid() => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 0.95,
        children: _types.map((t) {
          final selected = _type == t.$1;
          final color = t.$4;
          return GestureDetector(
            onTap: () => setState(() => _type = t.$1),
            child: AnimatedContainer(
              duration: 180.ms,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.14)
                    : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? color.withOpacity(0.55)
                      : AppTheme.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$3, color: color, size: 22),
                    const SizedBox(height: 6),
                    Text(t.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: selected
                                ? AppTheme.textPri
                                : AppTheme.textSec,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2)),
                  ]),
            ),
          );
        }).toList(),
      );

  Widget _row(List<Widget> children) =>
      Row(children: children.map((c) => c is SizedBox ? c : Expanded(child: c)).toList());

  Widget _field(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPri, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppTheme.textMuted, fontSize: 12),
          filled: true,
          fillColor: AppTheme.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          isDense: true,
        ),
      );

  Widget _generateBtn() => GradBtn(
        label: 'Generate Document',
        icon: Icons.auto_awesome_rounded,
        loading: _generating,
        width: double.infinity,
        onTap: _generating ? null : _generate,
      );

  Widget _successCard() => GlowCard(
        glow: AppTheme.success,
        bg: AppTheme.success.withOpacity(0.06),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 46),
          const SizedBox(height: 12),
          Text('Document Ready!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPri)),
          const SizedBox(height: 6),
          const Text('Your response PDF has been created',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: GradBtn(
                label: 'Open',
                icon: Icons.open_in_new_rounded,
                onTap: () => OpenFile.open(_outputPath!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GradBtn(
                label: 'New',
                icon: Icons.add_rounded,
                grad: AppTheme.goldGrad,
                onTap: () => setState(() {
                  _outputPath = null;
                  _instCtrl.clear();
                }),
              ),
            ),
          ]),
        ]),
      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut).fadeIn();
}
