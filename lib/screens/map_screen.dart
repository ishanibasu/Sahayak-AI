import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/emergency_request.dart';
import '../services/request_service.dart';

class MapScreen extends StatefulWidget {
  final EmergencyRequest? focusRequest;
  const MapScreen({super.key, this.focusRequest});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final RequestService _service = RequestService();
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  StreamSubscription? _sub;
  int _totalCount = 0;
  int _criticalCount = 0;

  static const _defaultCenter = LatLng(20.5937, 78.9629);

  // Dark map style — tactical look
  static const _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#0f0f0f"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#5a5a5a"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#0f0f0f"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
    {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#141414"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
    {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]''';

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);
  static const _red = Color(0xFFB71C1C);
  static const _redBright = Color(0xFFEF5350);
  static const _amber = Color(0xFFFFA000);
  static const _green = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFFF0EBE3);
  static const _textMuted = Color(0xFF5A5A5A);

  @override
  void initState() {
    super.initState();
    _sub = _service.watchOpenRequests().listen(_updateMarkers);
    if (widget.focusRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnRequest());
    }
  }

  void _updateMarkers(List<EmergencyRequest> requests) {
    setState(() {
      _totalCount = requests.length;
      _criticalCount = requests
          .where((r) => r.criticalityLevel == CriticalityLevel.critical)
          .length;

      _markers = requests.map((req) {
        final hue = switch (req.criticalityLevel) {
          CriticalityLevel.critical => BitmapDescriptor.hueRed,
          CriticalityLevel.high => BitmapDescriptor.hueOrange,
          CriticalityLevel.medium => BitmapDescriptor.hueYellow,
          CriticalityLevel.low => BitmapDescriptor.hueGreen,
        };
        return Marker(
          markerId: MarkerId(req.id),
          position: LatLng(req.latitude, req.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title:
                '${req.criticalityLevel.name.toUpperCase()} · SCORE ${req.criticalityScore}',
            snippet: req.description.length > 60
                ? '${req.description.substring(0, 60)}…'
                : req.description,
          ),
        );
      }).toSet();
    });
  }

  Future<void> _focusOnRequest() async {
    final ctrl = await _mapController.future;
    final req = widget.focusRequest!;
    ctrl.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(req.latitude, req.longitude), 15),
    );
  }

  Future<void> _applyMapStyle() async {
    final ctrl = await _mapController.future;
    ctrl.setMapStyle(_darkMapStyle);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (ctrl) {
              _mapController.complete(ctrl);
              _applyMapStyle();
            },
            initialCameraPosition: CameraPosition(
              target: widget.focusRequest != null
                  ? LatLng(widget.focusRequest!.latitude,
                      widget.focusRequest!.longitude)
                  : _defaultCenter,
              zoom: widget.focusRequest != null ? 15 : 5,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // ── Header overlay ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bg.withOpacity(0.95),
                    _bg.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 24,
                left: 8,
                right: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: _textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE MAP',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          fontFamily: 'Courier New',
                        ),
                      ),
                      Text(
                        'REAL-TIME INCIDENT FEED',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 9,
                          letterSpacing: 2,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Stats overlay (bottom) ─────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _StatChip(
                  label: 'ACTIVE',
                  value: '$_totalCount',
                  color: _totalCount > 0 ? _redBright : _textMuted,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'CRITICAL',
                  value: '$_criticalCount',
                  color: _criticalCount > 0 ? _redBright : _textMuted,
                ),
                const Spacer(),
                // Legend
                const _LegendDot(label: 'CRIT', color: Colors.red),
                const SizedBox(width: 10),
                const _LegendDot(label: 'HIGH', color: Colors.orange),
                const SizedBox(width: 10),
                const _LegendDot(label: 'MED', color: Colors.yellow),
                const SizedBox(width: 10),
                const _LegendDot(label: 'LOW', color: Colors.green),
              ],
            ),
          ),

          // ── My-location button ─────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                final ctrl = await _mapController.future;
                // Animate to user location (best-effort — geolocator not used here)
                ctrl.animateCamera(CameraUpdate.zoomIn());
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _surface,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.my_location, color: _textMuted, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.92),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Courier New',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5A5A5A),
              fontSize: 9,
              letterSpacing: 1.5,
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5A5A5A),
            fontSize: 8,
            letterSpacing: 1,
            fontFamily: 'Courier New',
          ),
        ),
      ],
    );
  }
}
