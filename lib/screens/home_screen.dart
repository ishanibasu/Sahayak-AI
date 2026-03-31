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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final RequestService _service = RequestService();
  bool _nearbyOnly = false;
  late final AnimationController _pulseCtrl;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF1A1A1A);
  static const _surfaceHigh = Color(0xFF212121);
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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final displayName =
        user.displayName?.toUpperCase() ?? user.email?.split('@').first.toUpperCase() ?? 'OPERATOR';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────
          _TopBar(
            displayName: displayName,
            nearbyOnly: _nearbyOnly,
            pulseCtrl: _pulseCtrl,
            onNearbyToggle: (v) => setState(() => _nearbyOnly = v),
            onMapTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MapScreen())),
            onSignOut: () => FirebaseAuth.instance.signOut(),
          ),

          // ── Divider ────────────────────────────────────────────
          Container(height: 1, color: _border),

          // ── Section label ──────────────────────────────────────
          Container(
            color: _surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _redBright.withOpacity(
                          0.5 + 0.5 * _pulseCtrl.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _redBright
                              .withOpacity(0.4 * _pulseCtrl.value),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LIVE INCIDENTS',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontFamily: 'Courier New',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_nearbyOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: _amber.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      '5 KM RADIUS',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontFamily: 'Courier New',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(height: 1, color: _border),

          // ── Feed ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<EmergencyRequest>>(
              stream: _service.watchOpenRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error.toString());
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                      top: 12, bottom: 100, left: 16, right: 16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final req = requests[i];
                    return RequestCard(
                      request: req,
                      onResolve: () => _service.resolveRequest(
                        req.id,
                        callerId: user.uid,
                      ),
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
          ),
        ],
      ),

      // ── SOS FAB ────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _SOSButton(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitRequestScreen(
              userId: user.uid,
              displayName: user.displayName ?? 'Anonymous',
            ),
          ),
        ),
        pulseCtrl: _pulseCtrl,
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String displayName;
  final bool nearbyOnly;
  final AnimationController pulseCtrl;
  final ValueChanged<bool> onNearbyToggle;
  final VoidCallback onMapTap;
  final VoidCallback onSignOut;

  static const _bg = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);
  static const _red = Color(0xFFB71C1C);
  static const _redBright = Color(0xFFEF5350);
  static const _textPrimary = Color(0xFFF0EBE3);
  static const _textMuted = Color(0xFF5A5A5A);

  const _TopBar({
    required this.displayName,
    required this.nearbyOnly,
    required this.pulseCtrl,
    required this.onNearbyToggle,
    required this.onMapTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
        left: 20,
        right: 8,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: _red.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1)
              ],
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SAHAYAK AI',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  fontFamily: 'Courier New',
                ),
              ),
              Text(
                'OPR: $displayName',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontFamily: 'Courier New',
                ),
              ),
            ],
          ),
          const Spacer(),

          // Nearby toggle
          Row(
            children: [
              Text(
                'NEARBY',
                style: TextStyle(
                  color: nearbyOnly ? _redBright : _textMuted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontFamily: 'Courier New',
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch.adaptive(
                  value: nearbyOnly,
                  onChanged: onNearbyToggle,
                  activeColor: _redBright,
                  inactiveThumbColor: const Color(0xFF3A3A3A),
                  inactiveTrackColor: const Color(0xFF252525),
                ),
              ),
            ],
          ),

          // Map icon
          _IconBtn(icon: Icons.map_outlined, onTap: onMapTap),
          _IconBtn(icon: Icons.logout_outlined, onTap: onSignOut),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  static const _textMuted = Color(0xFF5A5A5A);

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: _textMuted),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}

// ── SOS Floating Button ─────────────────────────────────────────────
class _SOSButton extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController pulseCtrl;

  static const _red = Color(0xFFB71C1C);
  static const _redBright = Color(0xFFEF5350);

  const _SOSButton({required this.onTap, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          width: 200,
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: _red.withOpacity(0.3 + 0.3 * pulseCtrl.value),
                blurRadius: 16 + 12 * pulseCtrl.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_alert,
                  color: Colors.white.withOpacity(0.9), size: 20),
              const SizedBox(width: 10),
              const Text(
                'BROADCAST SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  fontFamily: 'Courier New',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── States ──────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFB71C1C),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'SCANNING NETWORK...',
            style: TextStyle(
              color: Color(0xFF5A5A5A),
              fontSize: 11,
              letterSpacing: 2,
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                color: Color(0xFFEF5350), size: 40),
            const SizedBox(height: 16),
            const Text(
              'CONNECTION ERROR',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 12,
                letterSpacing: 2,
                fontFamily: 'Courier New',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5A5A5A),
                fontSize: 11,
                fontFamily: 'Courier New',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check,
                color: Color(0xFF2E7D32), size: 30),
          ),
          const SizedBox(height: 20),
          const Text(
            'ALL CLEAR',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 16,
              letterSpacing: 4,
              fontFamily: 'Courier New',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active incidents in your area',
            style: TextStyle(
              color: Color(0xFF5A5A5A),
              fontSize: 12,
              letterSpacing: 0.5,
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}
