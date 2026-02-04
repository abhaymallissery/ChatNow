import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatActionsSheet extends StatelessWidget {
  const ChatActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.userId;
    final saveRequest = chatProvider.saveRequest;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Chat Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),

          if (saveRequest != null && saveRequest.status == 'pending') ...[
             if (saveRequest.requestedBy != myId) ...[
               const Text('The other user wants to save this chat.', textAlign: TextAlign.center),
               const SizedBox(height: 12),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   ElevatedButton(
                     onPressed: () {
                       chatProvider.respondToSaveRequest('approved');
                       Navigator.pop(context);
                     },
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                     child: const Text('Approve'),
                   ),
                   OutlinedButton(
                     onPressed: () {
                       chatProvider.respondToSaveRequest('rejected');
                       Navigator.pop(context);
                     },
                     style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                     child: const Text('Reject'),
                   ),
                 ],
               ),
               const Divider(),
             ] else ...[
               const Text('Save request pending...', style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
               const Divider(),
             ]
          ] else if (saveRequest == null || saveRequest.status == 'rejected') ...[
             ElevatedButton.icon(
              onPressed: () {
                if (myId != null) {
                  chatProvider.requestSave(myId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save request sent')));
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Request to Save Chat'),
            ),
            const SizedBox(height: 12),
          ] else if (saveRequest.status == 'approved') ...[
            const Text('Chat Saved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
             const SizedBox(height: 12),
          ],

          OutlinedButton.icon(
            onPressed: () {
              chatProvider.clearChat();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat cleared locally')));
            },
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Clear Chat (Local)'),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Connection?'),
                  content: const Text('This will delete the pairing and all messages.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                )
              );

              if (confirm == true) {
                if (context.mounted) {
                  Navigator.pop(context); // Close sheet
                  await chatProvider.deleteConnection();
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Connection'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
