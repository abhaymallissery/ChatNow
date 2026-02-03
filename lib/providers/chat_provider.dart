import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pairing_model.dart';
import '../models/message_model.dart';
import '../models/save_request_model.dart';
import '../services/database_service.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseService _db;

  ChatProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  String? _currentPairingId;
  Pairing? _currentPairing;
  List<Message> _messages = [];
  SaveRequest? _saveRequest;
  DateTime? _clearedAt;

  StreamSubscription? _pairingSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _saveRequestSubscription;

  String? get currentPairingId => _currentPairingId;
  Pairing? get currentPairing => _currentPairing;
  List<Message> get messages {
    if (_clearedAt == null) return _messages;
    return _messages.where((m) => m.sentAt.toDate().isAfter(_clearedAt!)).toList();
  }
  SaveRequest? get saveRequest => _saveRequest;

  bool get isConnected => _currentPairing != null && _currentPairing!.status == 'active';

  // Create Pairing
  Future<String?> createPairing(String userId) async {
    String? code = await _db.createPairing(userId);
    if (code != null) {
      // Look up the pairingId. In the service createPairing creates both.
      // But createPairing only returned the code.
      // I should update DatabaseService to return both or just look it up.
      // Actually, I can't look it up easily without querying code.
      // Let's assume for now we wait for user to join or we listen to the code.

      // Better approach: Listen to the pairing via the code mapping.
      String? pairingId = await _db.getPairingIdFromCode(code);
      if (pairingId != null) {
        _setPairingId(pairingId);
      }
    }
    return code;
  }

  // Join Pairing
  Future<bool> joinPairing(String code, String userId) async {
    String? pairingId = await _db.joinPairing(code, userId);
    if (pairingId != null) {
      _setPairingId(pairingId);
      return true;
    }
    return false;
  }

  void _setPairingId(String pairingId) {
    _currentPairingId = pairingId;
    _clearedAt = null;
    _subscribeToPairing();
    _subscribeToMessages();
    _subscribeToSaveRequests();
    notifyListeners();
  }

  void _subscribeToPairing() {
    _pairingSubscription?.cancel();
    if (_currentPairingId != null) {
      _pairingSubscription = _db.streamPairing(_currentPairingId!).listen((pairing) {
        _currentPairing = pairing;
        if (pairing == null) {
           // Pairing deleted
           leaveChat();
        }
        notifyListeners();
      });
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    if (_currentPairingId != null) {
      _messagesSubscription = _db.streamMessages(_currentPairingId!).listen((msgs) {
        _messages = msgs;
        notifyListeners();
      });
    }
  }

  void _subscribeToSaveRequests() {
    _saveRequestSubscription?.cancel();
     if (_currentPairingId != null) {
      _saveRequestSubscription = _db.streamSaveRequest(_currentPairingId!).listen((req) {
        _saveRequest = req;
        notifyListeners();
      });
    }
  }

  Future<void> sendMessage(String senderId, String body) async {
    if (_currentPairingId != null) {
      await _db.sendMessage(_currentPairingId!, senderId, body);
    }
  }

  Future<void> requestSave(String userId) async {
     if (_currentPairingId != null) {
      await _db.requestSave(_currentPairingId!, userId);
    }
  }

  Future<void> respondToSaveRequest(String status) async {
     if (_currentPairingId != null) {
      await _db.updateSaveRequestStatus(_currentPairingId!, status);
    }
  }

  Future<void> deleteConnection() async {
    if (_currentPairingId != null) {
      await _db.deleteConnection(_currentPairingId!);
      leaveChat();
    }
  }

  void clearChat() {
    _clearedAt = DateTime.now();
    notifyListeners();
  }

  void leaveChat() {
    _currentPairingId = null;
    _currentPairing = null;
    _messages = [];
    _saveRequest = null;
    _pairingSubscription?.cancel();
    _messagesSubscription?.cancel();
    _saveRequestSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _pairingSubscription?.cancel();
    _messagesSubscription?.cancel();
    _saveRequestSubscription?.cancel();
    super.dispose();
  }
}
