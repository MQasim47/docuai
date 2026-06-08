// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/document_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  final _suggestions = const [
    'What is this document about?',
    'What are the key points?',
    'What is the main message?',
    'What are the important keywords?',
    'How long is the document?',
    'What type of document is this?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    context.read<DocumentProvider>().sendChat(text.trim());
    Future.delayed(300.ms, () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DocumentProvider>();
    return Column(children: [
      Expanded(
        child: p.chat.isEmpty
            ? _emptyState(context)
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: p.chat.length + (p.chatLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == p.chat.length) return _typing();
                  final m = p.chat[i];
                  return _Bubble(
                      text: m['text'], isUser: m['role'] == 'user', index: i);
                },
              ),
      ),
      _inputBar(p),
    ]);
  }

  Widget _emptyState(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(children: [
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.cyanGrad,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cyanGlow,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 28),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Ask about the document',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Powered by built-in keyword AI — no internet needed',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ..._suggestions.asMap().entries.map(
              (e) => GestureDetector(
                onTap: () => _send(e.value),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.chat_rounded,
                        color: AppTheme.primary, size: 15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              color: AppTheme.textSec, fontSize: 13)),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textMuted, size: 11),
                  ]),
                ),
              ).animate().fadeIn(delay: (e.key * 70).ms).slideX(begin: 0.1, end: 0),
            ),
          ]),
        ],
      );

  Widget _typing() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          _AiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 6, height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                        delay: (i * 200).ms,
                        onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.2, 1.2),
                        duration: 400.ms),
              ),
            ),
          ),
        ]),
      );

  Widget _inputBar(DocumentProvider p) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(
                    color: AppTheme.textPri, fontSize: 14),
                maxLines: 3, minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask anything about the document…',
                  hintStyle: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(13),
                ),
                onSubmitted: p.chatLoading ? null : _send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: p.chatLoading ? null : () => _send(_ctrl.text),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: p.chatLoading
                    ? const LinearGradient(
                        colors: [Color(0xFF1E2D40), Color(0xFF131E2C)])
                    : AppTheme.cyanGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: p.chatLoading ? [] : AppTheme.cyanGlow,
              ),
              child: Icon(
                p.chatLoading
                    ? Icons.hourglass_bottom_rounded
                    : Icons.send_rounded,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ]),
      );
}

// ── Bubble ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final int index;
  const _Bubble({required this.text, required this.isUser, required this.index});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[_AiAvatar(), const SizedBox(width: 8)],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser ? AppTheme.cyanGrad : null,
                  color: isUser ? null : AppTheme.bgCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.border),
                  boxShadow: isUser ? AppTheme.cyanGlow : [],
                ),
                child: Text(text,
                    style: TextStyle(
                        color:
                            isUser ? Colors.white : AppTheme.textSec,
                        fontSize: 13,
                        height: 1.55)),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 15,
                backgroundColor: AppTheme.bgSurface,
                child: const Icon(Icons.person,
                    color: AppTheme.textSec, size: 15),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.08 : -0.08, end: 0);
}

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            gradient: AppTheme.cyanGrad, shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 15),
      );
}
