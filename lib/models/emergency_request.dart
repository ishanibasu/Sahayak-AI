import 'package:cloud_firestore/cloud_firestore.dart';

enum CriticalityLevel { low, medium, high, critical }

enum RequestStatus { open, acknowledged, resolved }

class EmergencyRequest {
  final String id;
  final String userId;
  final String userDisplayName;
  final String description;
  final double latitude;
  final double longitude;
  final CriticalityLevel criticalityLevel;
  final int criticalityScore; // 1–100 from Gemini
  final RequestStatus status;
  final DateTime timestamp;

  const EmergencyRequest({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.criticalityLevel,
    required this.criticalityScore,
    required this.status,
    required this.timestamp,
  });

  /// Firestore → Dart
  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? 'Anonymous',
      description: data['description'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      criticalityLevel: CriticalityLevel.values.firstWhere(
        (e) => e.name == data['criticalityLevel'],
        orElse: () => CriticalityLevel.medium,
      ),
      criticalityScore: data['criticalityScore'] ?? 50,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.open,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Dart → Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userDisplayName': userDisplayName,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'criticalityLevel': criticalityLevel.name,
        'criticalityScore': criticalityScore,
        'status': status.name,
        'timestamp': FieldValue.serverTimestamp(),
        // GeoFlutterFire geohash for radius queries (Step 9)
        'geohash': _encodeGeohash(latitude, longitude),
        'position': {
          'geohash': _encodeGeohash(latitude, longitude),
          'geopoint': GeoPoint(latitude, longitude),
        },
      };

  // Simple pass-through — geoflutterfire_plus handles actual encoding
  static String _encodeGeohash(double lat, double lng) => '';
}
