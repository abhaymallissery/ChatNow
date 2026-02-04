import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String body;
  final Timestamp sentAt;

  Message({
    required this.messageId,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      messageId: id,
      senderId: data['senderId'] ?? '',
      body: data['body'] ?? '',
      sentAt: data['sentAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'body': body,
      'sentAt': sentAt,
    };
  }
}
