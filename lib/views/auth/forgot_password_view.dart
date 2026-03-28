import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/custom_appbar.dart';

/// Écran de réinitialisation de mot de passe
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailEnvoye = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final ok =
        await auth.reinitialiserMotDePasse(_emailCtrl.text.trim());

    if (ok && mounted) {
      setState(() => _emailEnvoye = true);
    } else if (mounted) {
      AppHelpers.showError(context, auth.errorMessage ?? 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: const CustomAppBar(titre: 'Mot de passe oublié'),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: _emailEnvoye ? _buildSuccess() : _buildForm(auth),
      ),
    );
  }

  Widget _buildForm(AuthController auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Réinitialiser votre\nmot de passe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Entrez votre email et nous vous enverrons\nun lien pour réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
            decoration: AppInputDecoration.standard(
              label: 'Adresse email',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 24),

          auth.isLoading
              ? const CircularProgressIndicator()
              : AppPrimaryButton(
                  label: 'Envoyer le lien',
                  icon: Icons.send,
                  onPressed: _envoyer,
                ),
          const SizedBox(height: 16),
          AppSecondaryButton(
            label: 'Retour à la connexion',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 56,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Un email de réinitialisation a été envoyé à\n${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Vérifiez votre boîte mail et\ncliquez sur le lien reçu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        AppPrimaryButton(
          label: 'Retour à la connexion',
          icon: Icons.login,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
