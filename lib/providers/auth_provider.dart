import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  ChatUser? _user;

  ChatUser? get user => _user;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _authService.user.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInAnonymously() async {
    await _authService.signInAnonymously();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
