import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scan_service.dart';

/// Formats utiles pour livres : EAN-13 (ISBN), QR/DataMatrix (souvent URL + ISBN), etc.
final List<BarcodeFormat> kFormatsScanLivre = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.itf,
  BarcodeFormat.qrCode,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.pdf417,
  BarcodeFormat.aztec,
];

/// Extrait un ISBN-10 ou ISBN-13 à partir du texte brut du scan (code-barres ou QR).
class IsbnScanHelper {
  IsbnScanHelper._();

  static String _nettoyer(String s) => s.replaceAll(RegExp(r'[\s\-]'), '');

  /// Tente de trouver un ISBN valide dans [raw] (URL, texte, digits seuls).
  static String? extraireIsbn(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;

    final uri = Uri.tryParse(t);
    if (uri != null) {
      final q = uri.queryParameters;
      for (final key in ['isbn', 'ISBN', 'ean', 'EAN']) {
        final v = q[key];
        if (v != null && v.isNotEmpty) {
          final n = _nettoyer(v);
          if (ScanService.estIsbnValide(n)) return n;
        }
      }
    }

    final reIsbn = RegExp(r'(?:97[89]\d{10}|\d{9}[\dXx])(?!\d)');
    for (final m in reIsbn.allMatches(t)) {
      final n = _nettoyer(m.group(0)!);
      if (ScanService.estIsbnValide(n)) return n;
    }

    final digits = StringBuffer();
    for (final r in t.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'\d').hasMatch(c)) {
        digits.write(c);
      } else if ((c == 'X' || c == 'x') && digits.length == 9) {
        digits.write('X');
      }
    }
    final only = digits.toString();
    if (only.length >= 13) {
      for (var i = 0; i <= only.length - 13; i++) {
        final slice = only.substring(i, i + 13);
        if (ScanService.estIsbnValide(slice)) return slice;
      }
    }
    if (only.length >= 10) {
      for (var i = 0; i <= only.length - 10; i++) {
        final slice = only.substring(i, i + 10);
        if (ScanService.estIsbnValide(slice)) return slice;
      }
    }

    return null;
  }

  /// Code « métier » après scan : préfère ISBN si trouvé, sinon chaîne nettoyée pour id/QR custom.
  static String? meilleurCodePourCatalogue(String? raw) {
    final isbn = extraireIsbn(raw);
    if (isbn != null) return isbn;
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }
}
