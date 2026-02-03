import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Stream of auth changes
  Stream<ChatUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Convert Firebase User to ChatUser
  ChatUser? _userFromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    return ChatUser(
      userId: user.uid,
      displayName: user.displayName ?? 'Anonymous User',
      photoUrl: user.photoURL,
    );
  }

  // Sign in anonymously
  Future<ChatUser?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return _userFromFirebaseUser(result.user);
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get current user id
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
