import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0F0F0F);
  static const _surface = Color(0xFF1A1A1A);
  static const _surfaceHigh = Color(0xFF242424);
  static const _border = Color(0xFF2E2E2E);
  static const _red = Color(0xFFB71C1C);
  static const _redBright = Color(0xFFEF5350);
  static const _textPrimary = Color(0xFFF0EBE3);
  static const _textMuted = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        await _auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          displayName: _nameCtrl.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(
                  fontFamily: 'Courier New', color: _textPrimary),
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Reusable field builder ─────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
      cursorColor: _redBright,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textMuted,
          fontSize: 12,
          letterSpacing: 0.8,
          fontFamily: 'Courier New',
        ),
        prefixIcon: Icon(icon, color: _textMuted, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _redBright),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _redBright, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: _redBright,
          fontSize: 11,
          fontFamily: 'Courier New',
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Subtle grid background ─────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Red accent bar (top-left) ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 3,
              height: MediaQuery.of(context).size.height,
              color: _red,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Logo block ───────────────────────
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _red,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _red.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SAHAYAK AI',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3,
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                    Text(
                                      'EMERGENCY RESPONSE SYSTEM',
                                      style: TextStyle(
                                        color: _textMuted,
                                        fontSize: 9,
                                        letterSpacing: 2.5,
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // ── Panel ────────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Panel header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    decoration: const BoxDecoration(
                                      color: _surfaceHigh,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      border: Border(
                                          bottom: BorderSide(color: _border)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: _redBright,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isLogin
                                              ? 'OPERATOR LOGIN'
                                              : 'CREATE ACCOUNT',
                                          style: const TextStyle(
                                            color: _textMuted,
                                            fontSize: 11,
                                            letterSpacing: 2,
                                            fontFamily: 'Courier New',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Fields
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        if (!_isLogin) ...[
                                          _field(
                                            controller: _nameCtrl,
                                            label: 'DISPLAY NAME',
                                            icon: Icons.person_outline,
                                            validator: (v) =>
                                                v == null || v.isEmpty
                                                    ? 'Name required'
                                                    : null,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        _field(
                                          controller: _emailCtrl,
                                          label: 'EMAIL ADDRESS',
                                          icon: Icons.alternate_email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (v) =>
                                              v == null || !v.contains('@')
                                                  ? 'Valid email required'
                                                  : null,
                                        ),
                                        const SizedBox(height: 12),
                                        _field(
                                          controller: _passwordCtrl,
                                          label: 'PASSWORD',
                                          icon: Icons.lock_outline,
                                          obscure: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: _textMuted,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                          ),
                                          validator: (v) =>
                                              v == null || v.length < 6
                                                  ? 'Min 6 characters'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Submit button ────────────────────
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _red.withOpacity(0.4),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'AUTHENTICATE'
                                            : 'CREATE ACCOUNT',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.5,
                                          fontFamily: 'Courier New',
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Toggle ───────────────────────────
                            TextButton(
                              onPressed: () {
                                setState(() => _isLogin = !_isLogin);
                                _animCtrl
                                  ..reset()
                                  ..forward();
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: _textMuted),
                              child: Text(
                                _isLogin
                                    ? 'No account? — Register here'
                                    : 'Already registered? — Sign in',
                                style: const TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Courier New',
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Footer ───────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(height: 1, width: 40, color: _border),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'SECURE CHANNEL · AES-256',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      fontFamily: 'Courier New',
                                    ),
                                  ),
                                ),
                                Container(height: 1, width: 40, color: _border),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle dot-grid background painter ────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
