import 'dart:async'; // ✅ ADDED (required for .wait)
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_request.dart';
import 'gemini_service.dart';

class RequestService {
  static const _collectionName = 'emergency_requests';

  final FirebaseFirestore _db;
  final GeminiService _gemini;
  final _uuid = const Uuid();

  RequestService({
    FirebaseFirestore? db,
    GeminiService? gemini,
  })  : _db = db ?? FirebaseFirestore.instance,
        _gemini = gemini ?? GeminiService();

  CollectionReference get _col => _db.collection(_collectionName);

  Stream<List<EmergencyRequest>> watchOpenRequests() {
    return _col
        .where('status', isEqualTo: 'open')
        .orderBy('criticalityScore', descending: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              try {
                return EmergencyRequest.fromFirestore(doc);
              } catch (_) {
                return null;
              }
            })
            .whereType<EmergencyRequest>()
            .toList());
  }

  Stream<List<EmergencyRequest>> watchNearbyRequests({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    const kmPerDegree = 111.0;
    final latDelta = radiusKm / kmPerDegree;

    final cosLat = cos(latitude * pi / 180).clamp(0.001, 1.0);
    final lngDelta = radiusKm / (kmPerDegree * cosLat);

    final radiusMetres = radiusKm * 1000;

    return _col
        .where('status', isEqualTo: 'open')
        .where('latitude',
            isGreaterThanOrEqualTo: latitude - latDelta,
            isLessThanOrEqualTo: latitude + latDelta)
        .snapshots()
        .map((snap) {
      final requests = snap.docs
          .map((doc) {
            try {
              return EmergencyRequest.fromFirestore(doc);
            } catch (_) {
              return null;
            }
          })
          .whereType<EmergencyRequest>()
          .where((r) {
            final distMetres = Geolocator.distanceBetween(
              latitude,
              longitude,
              r.latitude,
              r.longitude,
            );
            return distMetres <= radiusMetres;
          })
          .toList();

      requests.sort((a, b) => b.criticalityScore.compareTo(a.criticalityScore));
      return requests;
    });
  }

  Future<String> submitRequest({
    required String userId,
    required String userDisplayName,
    required String description,
  }) async {
    final (position, triage) = await (
      _getLocation(),
      _gemini.analyzeEmergency(description),
    ).wait;

    final id = _uuid.v4();
    final request = EmergencyRequest(
      id: id,
      userId: userId,
      userDisplayName: userDisplayName,
      description: description,
      latitude: position.latitude,
      longitude: position.longitude,
      criticalityLevel: triage.level,
      criticalityScore: triage.score,
      status: RequestStatus.open,
      timestamp: DateTime.now(),
    );

    await _col.doc(id).set({
      ...request.toFirestore(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    return id;
  }

  Future<void> resolveRequest(
    String requestId, {
    required String callerId,
  }) async {
    final doc = await _col.doc(requestId).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) throw Exception('Request $requestId not found.');
    if (data['userId'] != callerId) {
      throw Exception('Unauthorized: only the requester can resolve this.');
    }

    await _col.doc(requestId).update({'status': RequestStatus.resolved.name});
  }

  Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in your device settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
}
