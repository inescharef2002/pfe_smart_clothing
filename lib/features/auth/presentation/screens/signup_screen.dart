import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe_smart_clothing/core/di/injection.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'signin_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => sl<AuthCubit>(),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _formKey       = GlobalKey<FormState>();
  final _firstCtrl     = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  bool  _hidePass      = true;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state.isAuthenticated) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pushReplacement(ctx,
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
      },
      builder: (ctx, state) {
        return Scaffold(
          body: Stack(
            children: [
              // ── Gradient background ──────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2D0061),
                      Color(0xFF5B21B6),
                      Color(0xFF7C3AED),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Decorative circles ───────────────────────────────────
              Positioned(
                top: -70,
                right: -70,
                child: _circle(220, Colors.white.withValues(alpha: 0.06)),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: _circle(80, Colors.white.withValues(alpha: 0.07)),
              ),
              Positioned(
                top: 100,
                left: -50,
                child: _circle(160, Colors.white.withValues(alpha: 0.05)),
              ),

              // ── Main layout ──────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // ── Top bar (back + mini logo) ─────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.checkroom_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          const Text('Smart Clothing',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // ── Header text ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Créer un compte',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Rejoignez la communauté Smart Clothing',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.70),
                                  fontSize: 14)),
                        ],
                      ),
                    ),

                    // ── White card (scrollable) ────────────────────────
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(36)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 30,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                          child: Column(
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(children: [
                                  // Prénom + Nom
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _Field(
                                          controller: _firstCtrl,
                                          label: 'Prénom',
                                          icon: Icons.person_outline_rounded,
                                          validator: (v) => v!.isEmpty
                                              ? 'Requis'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _Field(
                                          controller: _lastCtrl,
                                          label: 'Nom',
                                          icon: Icons.person_outline_rounded,
                                          validator: (v) => v!.isEmpty
                                              ? 'Requis'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _Field(
                                    controller: _emailCtrl,
                                    label: 'Adresse email',
                                    icon: Icons.email_outlined,
                                    keyboard: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Email requis';
                                      if (!v.contains('@')) {
                                        return 'Email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _Field(
                                    controller: _passCtrl,
                                    label: 'Mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _hidePass,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _hidePass
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF9CA3AF),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _hidePass = !_hidePass),
                                    ),
                                    validator: (v) {
                                      if (v!.isEmpty) {
                                        return 'Mot de passe requis';
                                      }
                                      if (v.length < 6) {
                                        return 'Minimum 6 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                ]),
                              ),

                              const SizedBox(height: 28),

                              state.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF6D28D9)))
                                  : _Btn(
                                      label: "S'inscrire",
                                      onTap: _submit,
                                    ),

                              const SizedBox(height: 20),
                              const _OrDivider(),
                              const SizedBox(height: 20),

                              _GoogleBtn(
                                label: 'Continuer avec Google',
                                onTap: state.isLoading
                                    ? null
                                    : () => ctx
                                        .read<AuthCubit>()
                                        .signInWithGoogle(),
                              ),

                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Déjà un compte ?',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280))),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      ctx,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SignInScreen()),
                                    ),
                                    child: const Text('Se connecter',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6D28D9))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _circle(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F0FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFE9D5FF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFE9D5FF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Color(0xFF6D28D9), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400)),
        errorStyle:
            TextStyle(color: Colors.red.shade500, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('ou',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ),
      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
    ]);
  }
}

class _GoogleBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GoogleBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleGLogo(size: 24),
            SizedBox(width: 12),
            Text('Continuer avec Google',
                style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Google G logo (CustomPainter) ─────────────────────────────────────────────
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 24});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GLogoPainter()),
      );
}

class _GLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c    = Offset(s.width / 2, s.height / 2);
    final r    = s.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    void arc(double startDeg, double sweepDeg, Color color) {
      canvas.drawArc(
        rect,
        startDeg * (math.pi / 180),
        sweepDeg * (math.pi / 180),
        true,
        Paint()..color = color,
      );
    }

    arc(161, 172, const Color(0xFF4285F4)); // blue  – left
    arc(333,  71, const Color(0xFFEA4335)); // red   – top
    arc( 44,  38, const Color(0xFFFBBC05)); // yellow– right
    arc( 82,  79, const Color(0xFF34A853)); // green – bottom

    // Inner white circle (ring cutout)
    canvas.drawCircle(c, r * 0.62, Paint()..color = Colors.white);

    // White notch → forms the G shape
    canvas.drawRect(
      Rect.fromLTWH(c.dx - r * 0.05, c.dy - r * 0.22, r * 1.1, r * 0.44),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
