import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_logo.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey        = GlobalKey<FormState>();
  final _nomCtrl        = TextEditingController();
  final _prenomCtrl     = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _telCtrl        = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePass     = true;
  bool _obscureConfirm  = true;
  bool _showSuccess     = false;

  @override
  void dispose() {
    for (final c in [_nomCtrl, _prenomCtrl, _emailCtrl, _telCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.inscrire(
      email: _emailCtrl.text.trim(), motDePasse: _passCtrl.text,
      nom: _nomCtrl.text.trim(), prenom: _prenomCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
    );
    if (ok && mounted) setState(() => _showSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return const _SuccessScreen();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    const AppLogoCompact(size: 52),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Créer un compte',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Rejoignez la bibliothèque BiblioX',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card formulaire
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: _Field(label: 'Prénom', controller: _prenomCtrl,
                                icon: Icons.person_outline_rounded,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: _Field(label: 'Nom', controller: _nomCtrl,
                                icon: Icons.person_outline_rounded,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null)),
                          ]),
                          const SizedBox(height: 12),
                          _Field(label: 'Email', controller: _emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.email),
                          const SizedBox(height: 12),
                          _Field(label: 'Téléphone (optionnel)', controller: _telCtrl,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _Field(
                            label: 'Mot de passe', controller: _passCtrl,
                            icon: Icons.lock_outline_rounded, obscure: _obscurePass,
                            validator: AppValidators.motDePasse,
                            suffix: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            label: 'Confirmer le mot de passe', controller: _confirmCtrl,
                            icon: Icons.lock_outline_rounded, obscure: _obscureConfirm,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
                              return null;
                            },
                            suffix: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Erreur
                          Consumer<AuthController>(builder: (_, auth, __) {
                            if (auth.errorMessage == null) return const SizedBox();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(AppSizes.radius),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Text(auth.errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                  textAlign: TextAlign.center),
                            );
                          }),

                          Consumer<AuthController>(
                            builder: (_, auth, __) => AppPrimaryButton(
                              label: auth.isLoading ? 'Création...' : 'Créer mon compte',
                              gradient: const LinearGradient(
                                colors: [AppColors.accentDark, AppColors.accent],
                              ),
                              onPressed: auth.isLoading ? null : _register,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Déjà membre ? ',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                )),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Se connecter',
                                  style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                        ],
                      ),
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

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 130, showText: true),
                  const SizedBox(height: 40),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
                  ),
                  const SizedBox(height: 24),
                  const Text('Inscription réussie !',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Bienvenue dans la bibliothèque BiblioX !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.6)),
                  const SizedBox(height: 40),
                  AppPrimaryButton(
                    label: 'Commencer',
                    gradient: const LinearGradient(colors: [AppColors.accentDark, AppColors.accent]),
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
