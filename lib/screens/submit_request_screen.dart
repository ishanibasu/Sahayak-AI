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

class _SubmitRequestScreenState extends State<SubmitRequestScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _service = RequestService();
  bool _isLoading = false;
  int _loadingStep = 0; // 0=location, 1=AI, 2=broadcasting

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF1A1A1A);
  static const _surfaceHigh = Color(0xFF212121);
  static const _border = Color(0xFF2A2A2A);
  static const _red = Color(0xFFB71C1C);
  static const _redBright = Color(0xFFEF5350);
  static const _amber = Color(0xFFFFA000);
  static const _textPrimary = Color(0xFFF0EBE3);
  static const _textMuted = Color(0xFF5A5A5A);

  final _steps = [
    (icon: Icons.my_location, label: 'ACQUIRING GPS LOCK'),
    (icon: Icons.memory_outlined, label: 'AI TRIAGE IN PROGRESS'),
    (icon: Icons.cell_tower, label: 'BROADCASTING TO NETWORK'),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _loadingStep = 0;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _loadingStep = 1);

      await _service.submitRequest(
        userId: widget.userId,
        userDisplayName: widget.displayName,
        description: _controller.text.trim(),
      );

      setState(() => _loadingStep = 2);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ALERT BROADCASTED — VOLUNTEERS NOTIFIED',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 12,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(
                  fontFamily: 'Courier New', color: Colors.white),
            ),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                color: const Color(0xFF141414),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 14,
                  left: 8,
                  right: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: _textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY BROADCAST',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            fontFamily: 'Courier New',
                          ),
                        ),
                        Text(
                          'PRIORITY ALERT SYSTEM',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 9,
                            letterSpacing: 2,
                            fontFamily: 'Courier New',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: _redBright.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '5KM',
                        style: TextStyle(
                          color: _redBright,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: _border),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Warning banner ───────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: _amber.withOpacity(0.8), size: 18),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'This alert reaches all volunteers within 5 km. '
                                  'Only use for genuine emergencies.',
                                  style: TextStyle(
                                    color: Color(0xFFBCAAA4),
                                    fontSize: 12,
                                    height: 1.5,
                                    fontFamily: 'Courier New',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Input label ──────────────────────────
                        const Text(
                          'INCIDENT DESCRIPTION',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                            letterSpacing: 2.5,
                            fontFamily: 'Courier New',
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Text area ────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _border),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 6,
                            maxLength: 300,
                            autofocus: true,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              height: 1.6,
                              fontFamily: 'Courier New',
                              letterSpacing: 0.3,
                            ),
                            cursorColor: _redBright,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. "Person collapsed at the bus stop, not breathing, needs immediate help"',
                              hintStyle: TextStyle(
                                color: Color(0xFF3A3A3A),
                                fontSize: 13,
                                fontFamily: 'Courier New',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              counterStyle: TextStyle(
                                color: _textMuted,
                                fontSize: 10,
                                fontFamily: 'Courier New',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── AI note ──────────────────────────────
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: _textMuted, size: 13),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI will assess priority level and alert the right volunteers instantly.',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  fontFamily: 'Courier New',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Loading steps ────────────────────────
                        if (_isLoading) ...[
                          ..._steps.asMap().entries.map((e) {
                            final i = e.key;
                            final step = e.value;
                            final isDone = i < _loadingStep;
                            final isActive = i == _loadingStep;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: isDone
                                        ? const Icon(Icons.check,
                                            size: 16, color: Color(0xFF2E7D32))
                                        : isActive
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  color: _redBright,
                                                ),
                                              )
                                            : Icon(step.icon,
                                                size: 14, color: _border),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    step.label,
                                    style: TextStyle(
                                      color: isDone
                                          ? const Color(0xFF2E7D32)
                                          : isActive
                                              ? _textPrimary
                                              : _textMuted,
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                      fontFamily: 'Courier New',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom button ────────────────────────────────────
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF141414),
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _red.withOpacity(0.3),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cell_tower, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'BROADCAST SOS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  fontFamily: 'Courier New',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
