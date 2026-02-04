import 'package:chat_now/models/pairing_model.dart';
import 'package:chat_now/providers/auth_provider.dart';
import 'package:chat_now/providers/chat_provider.dart';
import 'package:chat_now/services/auth_service.dart';
import 'package:chat_now/services/database_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Full Pairing and Chat Flow', () async {
    // Setup Mocks
    final mockAuthA = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'userA', displayName: 'User A'));
    final mockAuthB = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'userB', displayName: 'User B'));
    final mockFirestore = FakeFirebaseFirestore();

    // Services
    final authServiceA = AuthService(auth: mockAuthA);
    final authServiceB = AuthService(auth: mockAuthB);
    final dbService = DatabaseService(db: mockFirestore); // Shared DB

    // Providers
    final authProviderA = AuthProvider(authService: authServiceA);
    final authProviderB = AuthProvider(authService: authServiceB);
    final chatProviderA = ChatProvider(db: dbService);
    final chatProviderB = ChatProvider(db: dbService);

    // Initial Auth State (Already signed in mocks, but need to trigger listener?)
    // In mock_firebase_auth, current user is available.
    // AuthProvider constructor listens to stream.
    // Wait for stream to emit.
    await Future.delayed(Duration.zero);

    // User A creates pairing
    final code = await chatProviderA.createPairing('userA');
    expect(code, isNotNull);

    // Verify Pairing Created in DB
    final codes = await mockFirestore.collection('pairingCodes').get();
    expect(codes.docs.length, 1);
    expect(codes.docs.first.id, code);
    final pairingId = codes.docs.first.get('pairingId');

    // User A should be listening to pairing now (via code lookup in provider)
    // Wait for async listeners
    await Future.delayed(Duration.zero);
    expect(chatProviderA.currentPairingId, pairingId);

    // User B joins pairing
    final joinSuccess = await chatProviderB.joinPairing(code!, 'userB');
    expect(joinSuccess, true);

    // Wait for listeners to update
    await Future.delayed(Duration.zero);

    // Verify Pairing Status
    expect(chatProviderA.isConnected, true);
    expect(chatProviderB.isConnected, true);
    expect(chatProviderA.currentPairing!.status, 'active');
    expect(chatProviderA.currentPairing!.participants, containsAll(['userA', 'userB']));

    // User A sends message
    await chatProviderA.sendMessage('userA', 'Hello from A');

    // Wait for stream
    await Future.delayed(Duration.zero);

    // User B should receive message
    expect(chatProviderB.messages.length, 1);
    expect(chatProviderB.messages.first.body, 'Hello from A');
    expect(chatProviderB.messages.first.senderId, 'userA');

    // User B clears chat (local)
    chatProviderB.clearChat();
    // Wait for notifyListeners
    await Future.delayed(Duration.zero);

    expect(chatProviderB.messages.isEmpty, true);

    // User A sends another message
    await chatProviderA.sendMessage('userA', 'Second message');
    await Future.delayed(Duration.zero);

    // User B should see new message but not old
    expect(chatProviderB.messages.length, 1);
    expect(chatProviderB.messages.first.body, 'Second message');

    // User B requests save
    await chatProviderB.requestSave('userB');

    // Wait for stream
    await Future.delayed(Duration.zero);

    // User A sees request
    expect(chatProviderA.saveRequest, isNotNull);
    expect(chatProviderA.saveRequest!.status, 'pending');
    expect(chatProviderA.saveRequest!.requestedBy, 'userB');

    // User A approves
    await chatProviderA.respondToSaveRequest('approved');

    // Wait for stream
    await Future.delayed(Duration.zero);

    // User B sees approved
    expect(chatProviderB.saveRequest!.status, 'approved');

    // User A deletes connection
    await chatProviderA.deleteConnection();

    // Wait for stream/deletion
    await Future.delayed(Duration.zero);

    // Verify deletion
    final pairingDoc = await mockFirestore.collection('pairings').doc(pairingId).get();
    expect(pairingDoc.exists, false);

    // Verify providers reset (leaveChat called)
    expect(chatProviderA.currentPairingId, isNull);
    // Note: User B might not reset immediately if stream error handling or "null" snapshot isn't handled perfectly in test timing
    // but in real app stream would send null or close.
    // Check DatabaseService streamPairing map: if !snapshot.exists return null.
    // Provider listens: if pairing == null -> leaveChat().
    // So B should also leave.

    // Need to allow stream to process the deletion event.
    await Future.delayed(Duration.zero);

    expect(chatProviderB.currentPairingId, isNull);
  });
}
