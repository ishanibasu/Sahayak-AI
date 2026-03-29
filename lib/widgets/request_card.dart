import 'package:flutter/material.dart';
import '../models/emergency_request.dart';

class RequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final VoidCallback? onResolve;
  final VoidCallback? onMapTap;

  const RequestCard({
    super.key,
    required this.request,
    this.onResolve,
    this.onMapTap,
  });

  Color get _levelColor => switch (request.criticalityLevel) {
        CriticalityLevel.critical => const Color(0xFFD32F2F),
        CriticalityLevel.high => const Color(0xFFF57C00),
        CriticalityLevel.medium => const Color(0xFFFBC02D),
        CriticalityLevel.low => const Color(0xFF388E3C),
      };

  IconData get _levelIcon => switch (request.criticalityLevel) {
        CriticalityLevel.critical => Icons.emergency,
        CriticalityLevel.high => Icons.warning_amber_rounded,
        CriticalityLevel.medium => Icons.info_outline,
        CriticalityLevel.low => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _levelColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _levelColor.withOpacity(0.15),
                  radius: 20,
                  child: Icon(_levelIcon, color: _levelColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userDisplayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatTime(request.timestamp),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Criticality Score Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _levelColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${request.criticalityScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Description ───────────────────────────────────────────────
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // ── Action Row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onMapTap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('View on Map'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Respond'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _levelColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
