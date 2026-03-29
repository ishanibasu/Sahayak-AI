import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_request.dart';
import '../services/request_service.dart';
import '../widgets/request_card.dart';
import 'map_screen.dart';
import 'submit_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RequestService _service = RequestService();
  bool _nearbyOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🚑 Sahayak AI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          // Nearby toggle
          Row(
            children: [
              const Text('Nearby', style: TextStyle(fontSize: 13)),
              Switch.adaptive(
                value: _nearbyOnly,
                onChanged: (v) => setState(() => _nearbyOnly = v),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Full Map View',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<EmergencyRequest>>(
        stream: _service.watchOpenRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  SizedBox(height: 12),
                  Text('No active emergencies nearby.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final req = requests[i];
              return RequestCard(
                request: req,
                onResolve: () => _service.resolveRequest(req.id),
                onMapTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(focusRequest: req),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitRequestScreen(
              userId: user.uid,
              displayName: user.displayName ?? 'Anonymous',
            ),
          ),
        ),
        icon: const Icon(Icons.add_alert),
        label: const Text('SOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}
