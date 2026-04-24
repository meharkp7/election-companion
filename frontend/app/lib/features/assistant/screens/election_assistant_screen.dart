import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../../../services/new_features_api_service.dart';

class ElectionAssistantScreen extends ConsumerStatefulWidget {
  const ElectionAssistantScreen({super.key});

  @override
  ConsumerState<ElectionAssistantScreen> createState() =>
      _ElectionAssistantScreenState();
}

class _ElectionAssistantScreenState
    extends ConsumerState<ElectionAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  List<String> _quickQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuickQuestions();
    _addSystemMessage(
        'Hello! I am your Election Companion AI. How can I help you today?');
  }

  Future<void> _loadQuickQuestions() async {
    try {
      final res = await NewFeaturesApiService.getQuickQuestions();
      setState(() {
        _quickQuestions = List<String>.from(res['questions'] ?? []);
      });
    } catch (e) {
      setState(() {
        _quickQuestions = [
          'What documents do I need?',
          'How do I find my booth?',
          'EVM is not working',
        ];
      });
    }
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'text': text,
        'time': DateTime.now(),
      });
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'time': DateTime.now(),
      });
    });
  }

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    _addUserMessage(text);
    _controller.clear();
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final user = ref.read(userProvider).value;
      final response = await NewFeaturesApiService.askAssistant(
        text,
        {
          'state': user?.state ?? 'Delhi',
          'isFirstTimeVoter': user?.isFirstTimeVoter ?? false,
          'age': user?.age ?? 25,
        },
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'assistant',
            'text': response['answer'],
            'actions': response['suggestedActions'],
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isTyping = false);
      _addSystemMessage(
          'Sorry, I encountered an error. Please try again or call 1950.');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Election AI Assistant'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _ChatBubble(
                  text: msg['text'],
                  isUser: isUser,
                  actions: msg['actions'],
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Assistant is thinking...',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (_messages.length == 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _quickQuestions
                    .map((q) => _QuickQuestionChip(
                          label: q,
                          onTap: () => _handleSend(q),
                        ))
                    .toList(),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about voting...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.orange,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _handleSend(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<dynamic>? actions;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.orange : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.ink,
                fontSize: 14,
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: actions!
                    .map((a) => ActionChip(
                          label: Text(a.toString(),
                              style: const TextStyle(fontSize: 10)),
                          onPressed: () {
                            // Handle action
                          },
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickQuestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.card,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.ink),
      ),
    );
  }
}
