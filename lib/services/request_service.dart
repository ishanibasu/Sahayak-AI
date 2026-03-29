import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_request.dart';
import 'gemini_service.dart';

class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GeminiService _gemini = GeminiService();
  final _uuid = const Uuid();

  CollectionReference get _col => _db.collection('emergency_requests');

  // ── All open requests (requires composite index: status + criticalityScore + timestamp)
  Stream<List<EmergencyRequest>> watchOpenRequests() {
    return _col
        .where('status', isEqualTo: 'open')
        .orderBy('criticalityScore', descending: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EmergencyRequest.fromFirestore).toList());
  }

  // ── Geofenced requests (requires composite index: status + latitude)
  Stream<List<EmergencyRequest>> watchNearbyRequests({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    const kmPerDegree = 111.0;
    final latDelta = radiusKm / kmPerDegree;
    final lngDelta = radiusKm / (kmPerDegree * cos(latitude * pi / 180));

    return _col
        .where('status', isEqualTo: 'open')
        .where('latitude',
            isGreaterThanOrEqualTo: latitude - latDelta,
            isLessThanOrEqualTo: latitude + latDelta)
        .snapshots()
        .map((snap) => snap.docs.map(EmergencyRequest.fromFirestore).where((r) {
              final dist = Geolocator.distanceBetween(
                latitude,
                longitude,
                r.latitude,
                r.longitude,
              );
              return dist <= radiusKm * 1000;
            }).toList()
              ..sort(
                  (a, b) => b.criticalityScore.compareTo(a.criticalityScore)));
  }

  // ── Submit with parallel location + AI triage
  Future<String> submitRequest({
    required String userId,
    required String userDisplayName,
    required String description,
  }) async {
    // ✅ Launch both concurrently
    final positionFuture = _getLocation();
    final triageFuture = _gemini.analyzeEmergency(description);

    final position = await positionFuture;
    final triage = await triageFuture;

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

    await _col.doc(id).set(request.toFirestore());
    return id;
  }

  Future<void> resolveRequest(String requestId) =>
      _col.doc(requestId).update({'status': RequestStatus.resolved.name});

  // ── Fixed location helper with deniedForever handling
  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
    );
  }
}
