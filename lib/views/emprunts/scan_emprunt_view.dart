import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/isbn_scan_helper.dart';

/// Scan QR/code-barres pour emprunt ou retour rapide d'un livre
class ScanEmpruntView extends StatefulWidget {
  final bool modeRetour; // false = emprunt, true = retour
  const ScanEmpruntView({super.key, this.modeRetour = false});

  @override
  State<ScanEmpruntView> createState() => _ScanEmpruntViewState();
}

class _ScanEmpruntViewState extends State<ScanEmpruntView> {
  late final MobileScannerController _scanCtrl = MobileScannerController(
    formats: kFormatsScanLivre,
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
  );
  bool _traitement = false;
  String? _dernierCode;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scanner'), backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
        body: const Center(child: Text('Le scanner n\'est pas disponible sur web.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.modeRetour ? 'Scanner — Retour' : 'Scanner — Emprunt'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Torch uniquement — pas de switchCamera (cause écran noir sur émulateur)
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scanCtrl.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        // Caméra
        MobileScanner(
          controller: _scanCtrl,
          onDetect: (capture) {
            if (_traitement) return;
            for (final b in capture.barcodes) {
              final raw = b.rawValue;
              if (raw == null || raw.isEmpty) continue;
              final code = raw;
              if (code == _dernierCode) return;
              _dernierCode = code;
              _traiterCode(code);
              return;
            }
          },
        ),

        // Overlay viseur — rectangle large adapté aux codes-barres EAN-13
        Center(
          child: Container(
            width: 300, height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentLight, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(children: [
              ..._coins(),
            ]),
          ),
        ),

        // Instruction
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cadrez le code-barres dans le rectangle — tenez le livre à 15-20 cm',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (_traitement) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.accentLight),
            ],
          ]),
        ),
      ]),
    );
  }

  List<Widget> _coins() {
    const size = 24.0;
    const thick = 3.0;
    final color = AppColors.accentLight;
    return [
      // Top-left
      Positioned(top: 0, left: 0, child: _Coin(color, size, thick, top: true, left: true)),
      // Top-right
      Positioned(top: 0, right: 0, child: _Coin(color, size, thick, top: true, left: false)),
      // Bottom-left
      Positioned(bottom: 0, left: 0, child: _Coin(color, size, thick, top: false, left: true)),
      // Bottom-right
      Positioned(bottom: 0, right: 0, child: _Coin(color, size, thick, top: false, left: false)),
    ];
  }

  Livre? _livreDepuisScan(LivreController livreCtrl, String codeBrut) {
    final livres = livreCtrl.livres;
    final t = codeBrut.trim();
    for (final l in livres) {
      if (l.id == t) return l;
    }
    final isbn = IsbnScanHelper.extraireIsbn(codeBrut);
    if (isbn != null) {
      for (final l in livres) {
        final clean = l.isbn.replaceAll(RegExp(r'[\s\-]'), '');
        if (clean == isbn) return l;
      }
    }
    final fallback = IsbnScanHelper.meilleurCodePourCatalogue(codeBrut);
    if (fallback != null && fallback != isbn) {
      for (final l in livres) {
        if (l.id == fallback) return l;
        final clean = l.isbn.replaceAll(RegExp(r'[\s\-]'), '');
        if (clean == fallback) return l;
      }
    }
    return null;
  }

  Future<void> _traiterCode(String code) async {
    setState(() => _traitement = true);
    await _scanCtrl.stop();

    try {
      final auth = context.read<AuthController>();
      final empruntCtrl = context.read<EmpruntController>();
      final livreCtrl = context.read<LivreController>();

      if (widget.modeRetour) {
        // Mode retour : résoudre livre (ISBN / id) puis emprunt actif
        final livre = _livreDepuisScan(livreCtrl, code);
        if (livre == null) {
          throw Exception(
            'Livre inconnu (scannez le code-barres ISBN ou l’identifiant du livre).',
          );
        }
        final emprunts = empruntCtrl.empruntsActifs;
        final emprunt = emprunts.firstWhere(
          (e) => e.livreId == livre.id,
          orElse: () => throw Exception('Aucun emprunt actif pour « ${livre.titre} ».'),
        );
        final ok = await empruntCtrl.retournerLivre(
          empruntId: emprunt.id,
          livreId: emprunt.livreId,
          membreId: auth.membre!.uid,
        );
        if (mounted) {
          if (ok) {
            AppHelpers.showSuccess(context, 'Retour enregistré pour "${emprunt.livreTitre}".');
          } else {
            AppHelpers.showError(context, empruntCtrl.errorMessage ?? 'Erreur');
          }
          Navigator.pop(context);
        }
      } else {
        final livre = _livreDepuisScan(livreCtrl, code);
        if (livre == null) {
          throw Exception(
            'Livre non trouvé. Vérifiez l’ISBN en base ou scannez le code-barres du livre.',
          );
        }
        if (!livre.estDisponible) {
          throw Exception('Ce livre n\'est pas disponible actuellement.');
        }
        if (mounted) {
          Navigator.pop(context, livre);
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showError(context, e.toString().replaceAll('Exception: ', ''));
        setState(() { _traitement = false; _dernierCode = null; });
        await _scanCtrl.start();
      }
    }
  }
}

class _Coin extends StatelessWidget {
  final Color color;
  final double size, thick;
  final bool top, left;
  const _Coin(this.color, this.size, this.thick, {required this.top, required this.left});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _CoinPainter(color, thick, top, left)),
  );
}

class _CoinPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top, left;
  const _CoinPainter(this.color, this.thick, this.top, this.left);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thick..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
