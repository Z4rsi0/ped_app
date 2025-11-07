import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service de synchronisation des données depuis GitHub
/// 
/// Architecture:
/// - GitHub: https://raw.githubusercontent.com/Z4rsi0/ped_app_data/main/assets/xxx.json
/// - Local: /data/user/0/.../app_flutter/assets/xxx.json
/// - Assets embarqués: assets/xxx.json (fallback)
class DataSyncService {
  static const String githubBaseUrl = 'https://raw.githubusercontent.com/Z4rsi0/ped_app_data/main';
  
  /// Liste des fichiers à synchroniser
  /// Clé = chemin relatif depuis la racine (avec assets/)
  /// Valeur = URL GitHub complète
  static const Map<String, String> files = {
    'assets/medicaments_pediatrie.json': '$githubBaseUrl/assets/medicaments_pediatrie.json',
    'assets/annuaire.json': '$githubBaseUrl/assets/annuaire.json',
    'assets/protocoles/etat_de_mal_epileptique.json': '$githubBaseUrl/assets/protocoles/etat_de_mal_epileptique.json',
    'assets/protocoles/arret_cardio_respiratoire.json': '$githubBaseUrl/assets/protocoles/arret_cardio_respiratoire.json',
  };

  /// Synchronise tous les fichiers depuis GitHub
  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    for (var entry in files.entries) {
      try {
        final downloaded = await _downloadFile(entry.key, entry.value);
        if (downloaded) {
          success++;
          debugPrint('✅ Synchronisé: ${entry.key}');
        } else {
          failed++;
          errors.add(entry.key);
          debugPrint('❌ Échec: ${entry.key}');
        }
      } catch (e) {
        failed++;
        errors.add('${entry.key}: $e');
        debugPrint('❌ Exception: ${entry.key} - $e');
      }
    }

    return SyncResult(
      success: success,
      failed: failed,
      errors: errors,
      totalFiles: files.length,
    );
  }

  /// Télécharge un fichier depuis GitHub
  static Future<bool> _downloadFile(String relativePath, String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$relativePath');
        
        // Créer les sous-répertoires si nécessaire
        await file.parent.create(recursive: true);
        await file.writeAsString(response.body);
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Lit un fichier (priorité: local > assets embarqués)
  /// 
  /// @param assetPath Chemin avec le préfixe 'assets/', ex: 'assets/annuaire.json'
  /// @return Contenu du fichier
  static Future<String> readFile(String assetPath) async {
    // S'assurer que le chemin commence par 'assets/'
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }

    // 1. Essayer de lire depuis le stockage local
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$assetPath');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        debugPrint('📖 LOCAL: $assetPath');
        return content;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lecture locale de $assetPath: $e');
    }

    // 2. Fallback sur les assets embarqués
    try {
      final content = await rootBundle.loadString(assetPath);
      debugPrint('📦 ASSETS: $assetPath');
      return content;
    } catch (e) {
      debugPrint('❌ Erreur assets $assetPath: $e');
      rethrow;
    }
  }

  /// Vérifie si un fichier existe localement
  static Future<bool> fileExistsLocally(String assetPath) async {
    try {
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/$assetPath';
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$assetPath');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Force le téléchargement d'un fichier spécifique
  static Future<bool> forceDownloadFile(String assetPath) async {
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }
    
    final url = files[assetPath];
    if (url == null) {
      debugPrint('❌ URL non trouvée pour: $assetPath');
      return false;
    }
    
    return await _downloadFile(assetPath, url);
  }

  /// Supprime tous les fichiers locaux (reset aux assets embarqués)
  static Future<void> clearLocalData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (var assetPath in files.keys) {
        final file = File('${dir.path}/$assetPath');
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Supprimé: $assetPath');
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

  /// Obtient le statut de synchronisation de tous les fichiers
  static Future<Map<String, bool>> getSyncStatus() async {
    Map<String, bool> status = {};
    
    for (var assetPath in files.keys) {
      status[assetPath] = await fileExistsLocally(assetPath);
    }
    
    return status;
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

  String get detailedMessage {
    if (allSuccess) {
      return message;
    } else {
      return '$message\n\nErreurs:\n${errors.map((e) => '• $e').join('\n')}';
    }
  }
}