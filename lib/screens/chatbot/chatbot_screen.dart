// lib/screens/chatbot/chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../main.dart';

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, this.isUser);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _ctrl      = TextEditingController();
  final _scroll    = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading  = false;

  final List<String> _suggestions = [
    'What should I eat today?',
    'Why is my energy low?',
    'Best foods for PCOS?',
    'How to reduce inflammation?',
    'What does HRV mean?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
        'Hi! I\'m NutriSync AI 🌿\nI can help you with nutrition advice, explain your metabolic state, or suggest meals. What would you like to know?',
        false));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text, true));
      _isLoading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    final checkin = context.read<CheckinProvider>();
    final auth    = context.read<AuthProvider>();

    final reply = await ApiService.askGemini(
      text,
      metabolicState: checkin.lastCheckin?.metabolicState,
      dietType: null,
    );

    setState(() {
      _messages.add(_Message(reply, false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NutriSync AI',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Nutrition Assistant',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick suggestions
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(_suggestions[i],
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () => _send(_suggestions[i]),
                ),
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[i];
                return _buildBubble(msg);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition...',
                      filled: true,
                      fillColor: const Color(0xFFF1F3F4),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _send(_ctrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppTheme.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Container(
            width: 6, height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
          )),
        ),
      ),
    );
  }
}
