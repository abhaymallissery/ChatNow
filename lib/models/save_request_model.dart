import 'package:cloud_firestore/cloud_firestore.dart';

class SaveRequest {
  final String pairingId;
  final String requestedBy;
  final Timestamp requestedAt;
  final String status; // pending, approved, rejected

  SaveRequest({
    required this.pairingId,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
  });

  factory SaveRequest.fromMap(Map<String, dynamic> data, String id) {
    return SaveRequest(
      pairingId: id,
      requestedBy: data['requestedBy'] ?? '',
      requestedAt: data['requestedAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestedBy': requestedBy,
      'requestedAt': requestedAt,
      'status': status,
    };
  }
}
