import 'package:cloud_firestore/cloud_firestore.dart';

class Pairing {
  final String pairingId;
  final Timestamp createdAt;
  final String createdBy;
  final List<String> participants;
  final String status; // pending, active, closed

  Pairing({
    required this.pairingId,
    required this.createdAt,
    required this.createdBy,
    required this.participants,
    required this.status,
  });

  factory Pairing.fromMap(Map<String, dynamic> data, String id) {
    return Pairing(
      pairingId: id,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'createdBy': createdBy,
      'participants': participants,
      'status': status,
    };
  }
}
