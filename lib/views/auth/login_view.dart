import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_logo.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.connecter(email: _emailCtrl.text.trim(), motDePasse: _passCtrl.text);
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Column(
            children: [
              // ── Hero header ──
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(size: 130, showText: true),
                      const SizedBox(height: 12),
                      Text('Votre bibliothèque de quartier',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13, letterSpacing: 0.3,
                          )),
                    ],
                  ),
                ),
              ),

              // ── Card formulaire ──
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connexion',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Bienvenue sur BiblioX',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 24),

                        // Google
                        _GoogleButton(),
                        const SizedBox(height: 18),

                        Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                )),
                          ),
                          const Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 18),

                        Form(
                          key: _formKey,
                          child: Column(children: [
                            _Field(
                              label: 'Email', controller: _emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.email,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              label: 'Mot de passe', controller: _passCtrl,
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              validator: AppValidators.motDePasse,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ]),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
                            child: const Text('Mot de passe oublié ?',
                                style: TextStyle(color: AppColors.accent, fontSize: 13)),
                          ),
                        ),

                        // Erreur
                        Consumer<AuthController>(builder: (_, auth, __) {
                          if (auth.errorMessage == null) return const SizedBox();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(AppSizes.radius),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(auth.errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13))),
                            ]),
                          );
                        }),

                        Consumer<AuthController>(
                          builder: (_, auth, __) => AppPrimaryButton(
                            label: auth.isLoading ? 'Connexion...' : 'Se connecter',
                            gradient: const LinearGradient(
                              colors: [AppColors.accentDark, AppColors.accent],
                            ),
                            onPressed: auth.isLoading ? null : _login,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Pas encore membre ? ',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              )),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const RegisterView())),
                            child: const Text('S\'inscrire',
                                style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bouton Google ────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AuthController>(
      builder: (_, auth, __) => OutlinedButton(
        onPressed: auth.isLoading ? null : () async {
          final ok = await auth.connecterAvecGoogle();
          if (!ok && context.mounted && auth.errorMessage != null) {
            AppHelpers.showError(context, auth.errorMessage!);
          } else if (ok && context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.border,
          ),
          backgroundColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Text('G', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
          ),
          const SizedBox(width: 10),
          Text('Continuer avec Google',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              )),
        ]),
      ),
    );
  }
}

// ─── Champ texte ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({
    required this.label, required this.controller, required this.icon,
    this.obscure = false, this.keyboardType, this.validator, this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, obscureText: obscure,
    keyboardType: keyboardType, validator: validator,
    decoration: AppInputDecoration.standard(
      label: label,
      icon: icon,
    ).copyWith(
      suffixIcon: suffix,
    ),
  );
}
