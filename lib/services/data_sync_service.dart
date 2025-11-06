import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DataSyncService {
  static const String githubBaseUrl = 'https://raw.githubusercontent.com/Z4rsi0/ped_app_data/main';
  
  static const Map<String, String> files = {
    'medicaments_pediatrie.json': '$githubBaseUrl/medicaments_pediatrie.json',
    'annuaire.json': '$githubBaseUrl/annuaire.json',
    'protocoles/etat_de_mal_epileptique.json': '$githubBaseUrl/protocoles/etat_de_mal_epileptique.json',
    'protocoles/arret_cardio_respiratoire.json': '$githubBaseUrl/protocoles/arret_cardio_respiratoire.json',
  };

  /// Vérifie et synchronise tous les fichiers au démarrage
  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    for (var entry in files.entries) {
      try {
        final downloaded = await _downloadFile(entry.key, entry.value);
        if (downloaded) {
          success++;
        } else {
          failed++;
          errors.add(entry.key);
        }
      } catch (e) {
        failed++;
        errors.add('${entry.key}: $e');
      }
    }

    return SyncResult(
      success: success,
      failed: failed,
      errors: errors,
      totalFiles: files.length,
    );
  }

  /// Télécharge un fichier depuis GitHub et le sauvegarde localement
  static Future<bool> _downloadFile(String filename, String url) async {
    try {
      // Télécharger depuis GitHub
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Sauvegarder localement
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        
        // Créer les dossiers si nécessaire
        await file.parent.create(recursive: true);
        
        await file.writeAsString(response.body);
        
        debugPrint('✅ Synchronisé: $filename');
        return true;
      } else {
        debugPrint('❌ Erreur ${response.statusCode} pour $filename');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception pour $filename: $e');
      return false;
    }
  }

  /// Lit un fichier (local en priorité, sinon assets)
  static Future<String> readFile(String filename) async {
    try {
      // Essayer de lire le fichier local d'abord
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      
      if (await file.exists()) {
        debugPrint('📖 Lecture locale: $filename');
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lecture locale de $filename: $e');
    }

    // Fallback sur les assets embarqués
    debugPrint('📦 Fallback assets: $filename');
    
    // Nettoyer le chemin pour les assets
    String assetPath = filename;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$filename';
    }
    
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      debugPrint('❌ Erreur chargement asset $assetPath: $e');
      rethrow;
    }
  }

  /// Force le téléchargement d'un fichier spécifique
  static Future<bool> forceDownloadFile(String filename) async {
    final url = files[filename];
    if (url == null) return false;
    return await _downloadFile(filename, url);
  }

  /// Supprime tous les fichiers locaux (reset aux assets)
  static Future<void> clearLocalData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (var filename in files.keys) {
        final file = File('${dir.path}/$filename');
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Supprimé: $filename');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Vérifie la connexion Internet
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 3),
      );
      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class SyncResult {
  final int success;
  final int failed;
  final List<String> errors;
  final int totalFiles;

  SyncResult({
    required this.success,
    required this.failed,
    required this.errors,
    required this.totalFiles,
  });

  bool get hasErrors => failed > 0;
  bool get allSuccess => failed == 0;
  
  String get message {
    if (allSuccess) {
      return '✅ Tous les fichiers sont à jour ($success/$totalFiles)';
    } else {
      return '⚠️ $success/$totalFiles synchronisés - $failed erreur(s)';
    }
  }
}