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

  // Default center: India
  static const _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _sub = _service.watchOpenRequests().listen(_updateMarkers);

    // If focused on one request, animate to it
    if (widget.focusRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnRequest());
    }
  }

  void _updateMarkers(List<EmergencyRequest> requests) {
    setState(() {
      _markers = requests.map((req) {
        final color = switch (req.criticalityLevel) {
          CriticalityLevel.critical => BitmapDescriptor.hueRed,
          CriticalityLevel.high => BitmapDescriptor.hueOrange,
          CriticalityLevel.medium => BitmapDescriptor.hueYellow,
          CriticalityLevel.low => BitmapDescriptor.hueGreen,
        };
        return Marker(
          markerId: MarkerId(req.id),
          position: LatLng(req.latitude, req.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title:
                '${req.criticalityLevel.name.toUpperCase()} — Score: ${req.criticalityScore}',
            snippet: req.description.length > 60
                ? '${req.description.substring(0, 60)}...'
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Emergency Map')),
      body: GoogleMap(
        onMapCreated: _mapController.complete,
        initialCameraPosition: CameraPosition(
          target: widget.focusRequest != null
              ? LatLng(
                  widget.focusRequest!.latitude, widget.focusRequest!.longitude)
              : _defaultCenter,
          zoom: widget.focusRequest != null ? 15 : 5,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
