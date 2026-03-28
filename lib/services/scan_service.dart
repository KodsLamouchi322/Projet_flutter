import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

/// Service de scan ISBN — sur web : saisie manuelle, sur mobile : caméra
class ScanService {
  /// Ouvre le scanner et retourne la valeur (ou null si annulé)
  static Future<String?> scanner(BuildContext context,
      {String titre = 'Scanner ISBN'}) async {
    if (kIsWeb) {
      return _scannerWeb(context, titre: titre);
    }

    // Hors Android/iOS, on conserve la saisie manuelle.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _scannerWeb(context, titre: titre);
    }

    final permission = await _ensureCameraPermission(context);
    if (!permission) {
      return _scannerWeb(context, titre: titre);
    }

    if (!context.mounted) return null;
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ISBNScannerPage(titre: titre),
      ),
    );
  }

  static Future<bool> _ensureCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission caméra requise'),
          content: const Text(
            'Activez la permission caméra dans les paramètres pour scanner un ISBN.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        ),
      );
    }

    return false;
  }

  static Future<String?> _scannerWeb(BuildContext context,
      {required String titre}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(titre),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Saisissez l\'ISBN du livre :',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: AppInputDecoration.standard(
                label: 'ISBN (10 ou 13 chiffres)',
                icon: Icons.numbers,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  /// Valide ISBN-10 ou ISBN-13
  static bool estIsbnValide(String valeur) {
    final clean = valeur.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.length == 10) return _validerIsbn10(clean);
    if (clean.length == 13) return _validerIsbn13(clean);
    return false;
  }

  static bool _validerIsbn10(String isbn) {
    int somme = 0;
    for (int i = 0; i < 9; i++) {
      final d = int.tryParse(isbn[i]);
      if (d == null) return false;
      somme += d * (10 - i);
    }
    final dernier = isbn[9].toUpperCase();
    somme += dernier == 'X' ? 10 : (int.tryParse(dernier) ?? -1);
    return somme % 11 == 0;
  }

  static bool _validerIsbn13(String isbn) {
    int somme = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.tryParse(isbn[i]);
      if (d == null) return false;
      somme += d * (i.isEven ? 1 : 3);
    }
    final cle = (10 - (somme % 10)) % 10;
    return cle == (int.tryParse(isbn[12]) ?? -1);
  }
}

class _ISBNScannerPage extends StatefulWidget {
  final String titre;
  const _ISBNScannerPage({required this.titre});

  @override
  State<_ISBNScannerPage> createState() => _ISBNScannerPageState();
}

class _ISBNScannerPageState extends State<_ISBNScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8],
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;

      final clean = raw.replaceAll(RegExp(r'[\s\-]'), '');
      if (!ScanService.estIsbnValide(clean)) continue;

      _processing = true;
      if (!mounted) return;
      Navigator.pop(context, clean);
      return;
    }
  }

  Future<void> _manualFallback() async {
    await _controller.stop();
    if (!mounted) return;

    final value = await ScanService._scannerWeb(context, titre: 'Saisie manuelle ISBN');
    if (!mounted) return;

    final clean = value?.replaceAll(RegExp(r'[\s\-]'), '') ?? '';
    if (clean.isNotEmpty && ScanService.estIsbnValide(clean)) {
      Navigator.pop(context, clean);
      return;
    }

    if (clean.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ISBN invalide. Réessayez.')),
      );
    }

    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.titre),
        actions: [
          IconButton(
            tooltip: 'Changer caméra',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Cadrez le code-barres ISBN (EAN-13 / EAN-8)',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _manualFallback,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Saisie manuelle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
