import 'package:flutter/material.dart';
import '../services/request_service.dart';

class SubmitRequestScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const SubmitRequestScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _controller = TextEditingController();
  final _service = RequestService();
  bool _isLoading = false;
  String _loadingMessage = '';

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = '📍 Getting your location...';
    });

    try {
      await Future.delayed(
          const Duration(milliseconds: 500)); // UX breathing room

      setState(() => _loadingMessage = '🤖 Analyzing emergency with AI...');

      await _service.submitRequest(
        userId: widget.userId,
        userDisplayName: widget.displayName,
        description: _controller.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emergency broadcasted to nearby volunteers!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Emergency Alert')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Text(
                '⚠️  This alert will be sent to all volunteers within 5km. '
                'Only use in genuine emergencies.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 300,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Describe the emergency',
                hintText:
                    'e.g. "Person collapsed at the bus stop, not breathing"',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our AI will assess priority and alert the right volunteers instantly.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),
            if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_loadingMessage,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('Broadcast SOS'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
