import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Dialog de confirmation réutilisable
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String titre,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  Color confirmColor = AppColors.primary,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor, size: 22),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titre,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 40),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Dialog d'information simple
Future<void> showInfoDialog({
  required BuildContext context,
  required String titre,
  required String message,
  String closeLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}

/// Dialog de saisie de texte
Future<String?> showInputDialog({
  required BuildContext context,
  required String titre,
  String? hintText,
  String confirmLabel = 'Valider',
  int maxLines = 1,
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl,
        maxLines: maxLines,
        autofocus: true,
        decoration: AppInputDecoration.standard(
          label: 'Saisie',
          icon: Icons.edit_outlined,
        ).copyWith(hintText: hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
