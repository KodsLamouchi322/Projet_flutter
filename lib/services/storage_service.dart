import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour l'upload et la gestion des fichiers Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─── Upload couverture de livre ───────────────────────────────────────────
  Future<String?> uploadCouvertureLivre({
    required String livreId,
    required File image,
    void Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('livres/$livreId/couverture.jpg');
      final uploadTask = ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snap) {
          final progress = snap.bytesTransferred / snap.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ─── Upload photo de profil ───────────────────────────────────────────────
  Future<String?> uploadPhotoProfil({
    required String membreId,
    required File image,
  }) async {
    try {
      final ref =
          _storage.ref().child('membres/$membreId/profil.jpg');
      await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ─── Upload image événement ───────────────────────────────────────────────
  Future<String?> uploadImageEvenement({
    required String evenementId,
    required File image,
  }) async {
    try {
      final ref =
          _storage.ref().child('evenements/$evenementId/cover.jpg');
      await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ─── Sélectionner une image depuis la galerie ─────────────────────────────
  Future<File?> choisirImageGalerie() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  // ─── Sélectionner une image via la caméra ─────────────────────────────────
  Future<File?> prendrePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  // ─── Supprimer un fichier ─────────────────────────────────────────────────
  Future<void> supprimerFichier(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
