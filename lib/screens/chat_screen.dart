import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_actions_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      chatProvider.sendMessage(authProvider.user!.userId, text);
      _messageController.clear();
    }
  }

  void _showActions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const ChatActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.messages;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.userId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Connected Chat'),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showActions,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Show newest at bottom (ListView reverse means index 0 is at bottom)
                  // But my stream returns List<Message>.
                  // If I want standard chat behavior, I should probably render in reverse order or use reverse: true and reversed list.
                  // The stream in DatabaseService uses `orderBy('sentAt', descending: true)`.
                  // So index 0 is the newest message.
                  // If I use `reverse: true` in ListView, index 0 is at the bottom.
                  // So this matches perfectly.
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.body),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(message.sentAt.toDate()),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
