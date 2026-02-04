class ChatUser {
  final String userId;
  final String displayName;
  final String? photoUrl;

  ChatUser({
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  factory ChatUser.fromMap(Map<String, dynamic> data, String userId) {
    return ChatUser(
      userId: userId,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
