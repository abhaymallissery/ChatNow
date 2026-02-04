import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/pairing_model.dart';
import '../models/message_model.dart';
import '../models/save_request_model.dart';

class DatabaseService {
  final FirebaseFirestore _db;
  final Uuid _uuid = const Uuid();

  DatabaseService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // --- Pairing ---

  // Create a new pairing and a corresponding code
  Future<String?> createPairing(String userId) async {
    try {
      String pairingId = _uuid.v4();
      String code = _uuid.v4().substring(0, 6).toUpperCase(); // Simple 6 char code

      // Create Pairing
      await _db.collection('pairings').doc(pairingId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
        'participants': [userId],
        'status': 'pending',
      });

      // Create Pairing Code mapping
      await _db.collection('pairingCodes').doc(code).set({
        'pairingId': pairingId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromMillisecondsSinceEpoch(
            DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch), // 10 mins expiry
      });

      return code;
    } catch (e) {
      print('Error creating pairing: $e');
      return null;
    }
  }

  // Join a pairing using a code
  Future<String?> joinPairing(String code, String userId) async {
    try {
      DocumentSnapshot codeDoc = await _db.collection('pairingCodes').doc(code).get();

      if (!codeDoc.exists) {
        throw Exception('Invalid code');
      }

      // Check expiry (optional, relying on data model for now)
      // Timestamp expiresAt = codeDoc.get('expiresAt');
      // if (Timestamp.now().compareTo(expiresAt) > 0) throw Exception('Code expired');

      String pairingId = codeDoc.get('pairingId');

      DocumentReference pairingRef = _db.collection('pairings').doc(pairingId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(pairingRef);
        if (!snapshot.exists) throw Exception('Pairing not found');

        List<dynamic> participants = snapshot.get('participants');
        if (participants.contains(userId)) {
           // Already joined
           return;
        }

        if (participants.length >= 2) {
          throw Exception('Pairing full');
        }

        participants.add(userId);
        transaction.update(pairingRef, {
          'participants': participants,
          'status': 'active',
        });
      });

      return pairingId;
    } catch (e) {
      print('Error joining pairing: $e');
      return null;
    }
  }

  // Stream of pairing status
  Stream<Pairing?> streamPairing(String pairingId) {
    return _db.collection('pairings').doc(pairingId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Pairing.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    });
  }

  // Look up pairing ID from code (for the creator to know which pairing to listen to)
  // Actually, the creator creates the pairingId, so they know it.
  // But if we want to get the pairing from the code:
  Future<String?> getPairingIdFromCode(String code) async {
      DocumentSnapshot codeDoc = await _db.collection('pairingCodes').doc(code).get();
      if (codeDoc.exists) {
        return codeDoc.get('pairingId');
      }
      return null;
  }

  // Listen to pairing by code (helper for creator)
  Stream<Pairing?> streamPairingByCode(String code) async* {
     String? pairingId = await getPairingIdFromCode(code);
     if (pairingId != null) {
       yield* streamPairing(pairingId);
     }
  }


  // --- Chat ---

  Future<void> sendMessage(String pairingId, String senderId, String body) async {
    try {
      await _db
          .collection('chats')
          .doc(pairingId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<List<Message>> streamMessages(String pairingId) {
    return _db
        .collection('chats')
        .doc(pairingId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- Actions ---

  // Clear Chat (Local mainly, but if we want to delete from server)
  // Prompt says: "Clear (keep connection): remove the local chat history but keep the pairing active."
  // This implies local deletion. But if it's Firebase backed, we might not delete from server unless we want to hide it.
  // Implementing "Delete connection" as deleting the pairing and messages.

  Future<void> deleteConnection(String pairingId) async {
     try {
       // Delete pairing
       await _db.collection('pairings').doc(pairingId).delete();

       // Delete messages (This requires cloud function ideally for subcollections, or client side loop)
       var messages = await _db.collection('chats').doc(pairingId).collection('messages').get();
       for (var doc in messages.docs) {
         await doc.reference.delete();
       }

       // Delete code? (Code might be expired anyway)
     } catch (e) {
       print('Error deleting connection: $e');
     }
  }

  // Save Request
  Future<void> requestSave(String pairingId, String userId) async {
    await _db.collection('saveRequests').doc(pairingId).set({
      'requestedBy': userId,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<SaveRequest?> streamSaveRequest(String pairingId) {
    return _db.collection('saveRequests').doc(pairingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SaveRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> updateSaveRequestStatus(String pairingId, String status) async {
    await _db.collection('saveRequests').doc(pairingId).update({
      'status': status,
    });
  }
}
