import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/emprunt.dart';
import '../utils/helpers.dart';
import '../widgets/pdf_preview_dialog.dart';

/// Service d'export PDF — reçus d'emprunt et rapports admin
class PdfService {

  // ─── Reçu d'emprunt pour le membre ───────────────────────────────────────
  static Future<void> genererRecuEmprunt({
    required BuildContext context,
    required Emprunt emprunt,
    required String membreNom,
    required String membreEmail,
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BiblioX', style: pw.TextStyle(
                  fontSize: 28, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                )),
                pw.Text('Bibliothèque de Quartier',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('REÇU D\'EMPRUNT', style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                )),
                pw.Text('N° ${emprunt.id.substring(0, 8).toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ]),
            ],
          ),
          pw.Divider(color: PdfColors.blue800, thickness: 2),
          pw.SizedBox(height: 20),

          // Infos membre
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('MEMBRE', style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800,
              )),
              pw.SizedBox(height: 8),
              pw.Text(membreNom, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(membreEmail, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ]),
          ),
          pw.SizedBox(height: 16),

          // Infos livre
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('LIVRE EMPRUNTÉ', style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800,
              )),
              pw.SizedBox(height: 8),
              pw.Text(emprunt.livreTitre, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('par ${emprunt.livreAuteur}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ]),
          ),
          pw.SizedBox(height: 16),

          // Dates
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  _cellHeader('Date d\'emprunt'),
                  _cellHeader('Date de retour prévue'),
                  _cellHeader('Prolongations'),
                ],
              ),
              pw.TableRow(children: [
                _cell(AppHelpers.formatDate(emprunt.dateEmprunt)),
                _cell(AppHelpers.formatDate(emprunt.dateRetourPrevue)),
                _cell('${emprunt.prolongations} / ${2}'),
              ]),
            ],
          ),
          pw.SizedBox(height: 24),

          // Conditions
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CONDITIONS D\'EMPRUNT', style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800,
              )),
              pw.SizedBox(height: 6),
              pw.Text('• Le livre doit être retourné en bon état avant la date prévue.',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• En cas de retard, des pénalités peuvent s\'appliquer.',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('• La prolongation est soumise à l\'autorisation de l\'administrateur.',
                  style: const pw.TextStyle(fontSize: 10)),
            ]),
          ),
          pw.Spacer(),

          // Pied de page
          pw.Divider(color: PdfColors.grey400),
          pw.Center(
            child: pw.Text(
              'BiblioX — Généré le ${AppHelpers.formatDateHeure(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    ));

    final date = DateTime.now();
    final safeTitre = emprunt.livreTitre
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final fileName = 'recu_emprunt_${safeTitre}_${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.pdf';
    await _sauvegarderEtProposerPartage(
      context: context,
      bytes: await doc.save(),
      fileName: fileName,
    );
  }

  // ─── Rapport statistiques admin ───────────────────────────────────────────
  static Future<void> genererRapportAdmin({
    required BuildContext context,
    required Map<String, int> stats,
    required List<Map<String, dynamic>> topLivres,
    required int periode, // nombre de jours
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BiblioX', style: pw.TextStyle(
                  fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800,
                )),
                pw.Text('Rapport Statistiques — $periode derniers jours',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ]),
              pw.Text(AppHelpers.formatDate(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
          pw.Divider(color: PdfColors.blue800, thickness: 2),
          pw.SizedBox(height: 20),

          // Stats globales
          pw.Text('STATISTIQUES GLOBALES', style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800,
          )),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _statBox('Total livres', '${stats['totalLivres'] ?? 0}', PdfColors.blue800),
            pw.SizedBox(width: 10),
            _statBox('Disponibles', '${stats['livresDisponibles'] ?? 0}', PdfColors.green700),
            pw.SizedBox(width: 10),
            _statBox('Membres', '${stats['totalMembres'] ?? 0}', PdfColors.orange800),
            pw.SizedBox(width: 10),
            _statBox('Emprunts actifs', '${stats['empruntsEnCours'] ?? 0}', PdfColors.red700),
          ]),
          pw.SizedBox(height: 24),

          // Top livres
          if (topLivres.isNotEmpty) ...[
            pw.Text('TOP LIVRES LES PLUS EMPRUNTÉS', style: pw.TextStyle(
              fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800,
            )),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(60),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _cellHeader('#'),
                    _cellHeader('Titre'),
                    _cellHeader('Auteur'),
                    _cellHeader('Emprunts'),
                  ],
                ),
                ...topLivres.take(10).toList().asMap().entries.map((e) =>
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: e.key.isEven ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      _cell('${e.key + 1}'),
                      _cell(e.value['titre'] ?? ''),
                      _cell(e.value['auteur'] ?? ''),
                      _cell('${e.value['nbEmpruntsTotal'] ?? 0}'),
                    ],
                  ),
                ),
              ],
            ),
          ],

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.Center(
            child: pw.Text(
              'BiblioX — Rapport généré le ${AppHelpers.formatDateHeure(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    ));

    final date = DateTime.now();
    final fileName =
        'rapport_admin_${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.pdf';
    await _sauvegarderEtProposerPartage(
      context: context,
      bytes: await doc.save(),
      fileName: fileName,
    );
  }

  static Future<void> _sauvegarderEtProposerPartage({
    required BuildContext context,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      throw Exception('La sauvegarde locale PDF n\'est pas prise en charge sur le Web.');
    }

    // Afficher le dialog de prévisualisation avec boutons de téléchargement et partage
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => PdfPreviewDialog(
        pdfBytes: bytes,
        fileName: fileName,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static pw.Widget _cellHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: pw.TextStyle(
      color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10,
    )),
  );

  static pw.Widget _cell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _statBox(String label, String value, PdfColor color) =>
    pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(children: [
          pw.Text(value, style: pw.TextStyle(
            fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
          )),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
              textAlign: pw.TextAlign.center),
        ]),
      ),
    );
}
