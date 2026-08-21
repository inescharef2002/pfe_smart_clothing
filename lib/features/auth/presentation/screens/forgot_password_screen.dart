import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe_smart_clothing/core/di/injection.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'signin_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
  final _emailCtrl     = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().sendPasswordReset(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state.isPasswordResetSent) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: const Text('Email de réinitialisation envoyé ! Vérifiez votre boîte mail'),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    colors: [Color(0xFF2D0061), Color(0xFF5B21B6), Color(0xFF7C3AED)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Decorative circles ───────────────────────────────────
              ..._decorCircles(),

              // ── Main layout ──────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Header zone on gradient
                    Expanded(
                      flex: 4,
                      child: _HeaderSection(email: _emailCtrl.text),
                    ),

                    // White card
                    Expanded(
                      flex: 6,
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
                          child: state.isPasswordResetSent
                              ? _buildSuccessView(ctx, state)
                              : _buildFormView(ctx, state),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Back button ──────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormView(BuildContext ctx, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mot de passe oublié ?',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('Entrez votre email pour recevoir un lien de réinitialisation',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 28),

        Form(
          key: _formKey,
          child: _FpField(
            controller: _emailCtrl,
            label: 'Adresse email',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              if (v!.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
        ),

        const SizedBox(height: 24),
        state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6D28D9)))
            : _FpButton(label: 'Envoyer le lien', onTap: _submit),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Vous vous souvenez ?',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                ctx,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
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
    );
  }

  Widget _buildSuccessView(BuildContext ctx, AuthState state) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_read_outlined,
              size: 36, color: Colors.green.shade600),
        ),
        const SizedBox(height: 20),
        const Text('Email envoyé !',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        const Text(
          'Nous avons envoyé un lien de réinitialisation à :',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 6),
        Text(
          _emailCtrl.text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D28D9),
              fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cliquez sur le lien dans l\'email. Vérifiez aussi vos spams.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _FpButton(
          label: 'Retour à la connexion',
          onTap: () => Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final String email;
  const _HeaderSection({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 16),
        const Text('Smart Clothing',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text('RÉINITIALISATION',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Decorative circles ────────────────────────────────────────────────────────
List<Widget> _decorCircles() => [
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
        top: 120,
        left: -50,
        child: _circle(160, Colors.white.withValues(alpha: 0.05)),
      ),
      Positioned(
        bottom: 280,
        left: 30,
        child: _circle(40, Colors.white.withValues(alpha: 0.1)),
      ),
    ];

Widget _circle(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

// ── Reusable field ────────────────────────────────────────────────────────────
class _FpField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _FpField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F0FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9D5FF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9D5FF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFF6D28D9), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400)),
        errorStyle: TextStyle(color: Colors.red.shade500, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

// ── Button ────────────────────────────────────────────────────────────────────
class _FpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FpButton({required this.label, required this.onTap});

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
