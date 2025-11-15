import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de synchronisation des données depuis GitHub
/// 
/// Architecture:
/// - GitHub API: https://api.github.com/repos/Z4rsi0/ped_app_data/contents/assets/xxx.json
/// - Local: /data/user/0/.../app_flutter/assets/xxx.json
/// - Assets embarqués: assets/xxx.json (fallback)
/// 
/// Utilisation de l'API GitHub pour:
/// - Éviter le cache CDN de raw.githubusercontent.com
/// - Vérification conditionnelle via SHA
/// - Téléchargement uniquement si fichier modifié
/// - Découverte automatique des protocoles
class DataSyncService {
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubOwner = 'Z4rsi0';
  static const String githubRepo = 'ped_app_data';
  static const String githubBranch = 'main';
  
  /// Liste des fichiers de base à synchroniser (hors protocoles)
  /// Clé = chemin relatif depuis la racine (avec assets/)
  /// Valeur = chemin dans le repo GitHub
  static const Map<String, String> baseFiles = {
    'assets/medicaments_pediatrie.json': 'assets/medicaments_pediatrie.json',
    'assets/annuaire.json': 'assets/annuaire.json',
  };
  
  /// Cache des fichiers de protocoles découverts
  static Map<String, String>? _protocolesCache;

  /// Découvre tous les fichiers JSON dans le dossier protocoles
  static Future<Map<String, String>> _discoverProtocoles() async {
    if (_protocolesCache != null) {
      debugPrint('📋 Utilisation du cache protocoles (${_protocolesCache!.length} fichiers)');
      return _protocolesCache!;
    }

    try {
      final apiUrl = '$githubApiBase/assets/protocoles?ref=$githubBranch';
      
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
      };
      
      final token = dotenv.env['GITHUB_TOKEN'];
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('❌ Erreur API GitHub: ${response.statusCode}');
        return {};
      }

      final List<dynamic> contents = json.decode(response.body);
      final Map<String, String> protocoles = {};
      
      for (var item in contents) {
        if (item['type'] == 'file' && item['name'].toString().endsWith('.json')) {
          final filename = item['name'] as String;
          final path = 'assets/protocoles/$filename';
          protocoles[path] = 'assets/protocoles/$filename';
          debugPrint('📄 Protocole découvert: $filename');
        }
      }
      
      _protocolesCache = protocoles;
      debugPrint('✅ ${protocoles.length} protocoles découverts');
      return protocoles;
    } catch (e) {
      debugPrint('❌ Erreur découverte protocoles: $e');
      return {};
    }
  }

  /// Obtient la liste complète des fichiers (base + protocoles)
  static Future<Map<String, String>> getAllFiles() async {
    final protocoles = await _discoverProtocoles();
    return {...baseFiles, ...protocoles};
  }

  /// Synchronise tous les fichiers depuis GitHub
  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    int upToDate = 0;
    List<String> errors = [];

    // Récupérer tous les fichiers (base + protocoles découverts)
    final files = await getAllFiles();
    debugPrint('🔄 Synchronisation de ${files.length} fichiers...');

    for (var entry in files.entries) {
      try {
        final result = await _downloadFile(entry.key, entry.value);
        if (result == DownloadResult.success) {
          success++;
          debugPrint('✅ Synchronisé: ${entry.key}');
        } else if (result == DownloadResult.upToDate) {
          upToDate++;
          debugPrint('⏭️ Déjà à jour: ${entry.key}');
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
      upToDate: upToDate,
      errors: errors,
      totalFiles: files.length,
    );
  }

  /// Télécharge un fichier depuis GitHub si nécessaire
  /// Utilise l'API GitHub pour vérifier le SHA et éviter le cache CDN
  static Future<DownloadResult> _downloadFile(String relativePath, String githubPath) async {
    try {
      // 1. Récupérer le SHA local stocké
      final prefs = await SharedPreferences.getInstance();
      final shaKey = 'sha_$relativePath';
      final localSha = prefs.getString(shaKey);

      // 2. Interroger l'API GitHub pour obtenir les métadonnées du fichier
      final apiUrl = '$githubApiBase/$githubPath?ref=$githubBranch';
      
      // Préparer les headers avec le token si disponible
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
      };
      
      // Utiliser le token GitHub depuis .env si disponible
      final token = dotenv.env['GITHUB_TOKEN'];
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('🔑 Utilisation du token GitHub (rate limit: 5000 req/h)');
      } else {
        debugPrint('⚠️ Pas de token GitHub (rate limit: 60 req/h)');
      }
      
      final apiResponse = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode != 200) {
        debugPrint('❌ API GitHub erreur ${apiResponse.statusCode} pour $githubPath');
        return DownloadResult.failed;
      }

      final apiData = json.decode(apiResponse.body);
      final remoteSha = apiData['sha'] as String?;
      final downloadUrl = apiData['download_url'] as String?;

      if (remoteSha == null || downloadUrl == null) {
        debugPrint('❌ Données API incomplètes pour $githubPath');
        return DownloadResult.failed;
      }

      // 3. Comparer les SHA - si identiques, ne pas télécharger
      if (localSha == remoteSha) {
        debugPrint('✓ Fichier déjà à jour (SHA: ${remoteSha.substring(0, 7)})');
        return DownloadResult.upToDate;
      }

      // 4. Télécharger le contenu via download_url
      debugPrint('⬇️ Téléchargement de $githubPath (SHA: ${remoteSha.substring(0, 7)})');
      final contentResponse = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      if (contentResponse.statusCode != 200) {
        debugPrint('❌ Téléchargement échoué: ${contentResponse.statusCode}');
        return DownloadResult.failed;
      }

      // 5. Sauvegarder le fichier localement
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$relativePath');
      
      await file.parent.create(recursive: true);
      await file.writeAsString(contentResponse.body);

      // 6. Stocker le nouveau SHA
      await prefs.setString(shaKey, remoteSha);
      
      debugPrint('✅ Sauvegardé: ${file.path}');
      return DownloadResult.success;

    } catch (e) {
      debugPrint('❌ Exception _downloadFile: $e');
      return DownloadResult.failed;
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

  /// Force le téléchargement d'un fichier spécifique (ignore SHA)
  static Future<bool> forceDownloadFile(String assetPath) async {
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }
    
    final files = await getAllFiles();
    final githubPath = files[assetPath];
    if (githubPath == null) {
      debugPrint('❌ URL non trouvée pour: $assetPath');
      return false;
    }
    
    // Supprimer le SHA local pour forcer le téléchargement
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sha_$assetPath');
    
    final result = await _downloadFile(assetPath, githubPath);
    return result == DownloadResult.success;
  }

  /// Supprime tous les fichiers locaux (reset aux assets embarqués)
  static Future<void> clearLocalData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();
      
      final files = await getAllFiles();
      for (var assetPath in files.keys) {
        // Supprimer le fichier
        final file = File('${dir.path}/$assetPath');
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Supprimé: $assetPath');
        }
        
        // Supprimer le SHA
        await prefs.remove('sha_$assetPath');
      }
      
      // Vider le cache des protocoles
      _protocolesCache = null;
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
  static Future<Map<String, FileSyncStatus>> getSyncStatus() async {
    Map<String, FileSyncStatus> status = {};
    final prefs = await SharedPreferences.getInstance();
    
    final files = await getAllFiles();
    for (var assetPath in files.keys) {
      final exists = await fileExistsLocally(assetPath);
      final sha = prefs.getString('sha_$assetPath');
      
      status[assetPath] = FileSyncStatus(
        existsLocally: exists,
        sha: sha,
      );
    }
    
    return status;
  }

  /// Obtient des informations détaillées sur un fichier
  static Future<FileInfo?> getFileInfo(String assetPath) async {
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }
    
    final files = await getAllFiles();
    final githubPath = files[assetPath];
    if (githubPath == null) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final localSha = prefs.getString('sha_$assetPath');
      
      final apiUrl = '$githubApiBase/$githubPath?ref=$githubBranch';
      final apiResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode == 200) {
        final apiData = json.decode(apiResponse.body);
        return FileInfo(
          path: assetPath,
          remoteSha: apiData['sha'],
          localSha: localSha,
          size: apiData['size'],
          isUpToDate: localSha == apiData['sha'],
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur getFileInfo: $e');
    }
    
    return null;
  }

  /// Liste tous les protocoles disponibles
  static Future<List<String>> listProtocoles() async {
    final protocoles = await _discoverProtocoles();
    return protocoles.keys
        .where((path) => path.startsWith('assets/protocoles/'))
        .map((path) => path.replaceAll('assets/protocoles/', '').replaceAll('.json', ''))
        .toList();
  }
}

/// Résultat du téléchargement
enum DownloadResult {
  success,
  upToDate,
  failed,
}

/// Statut de synchronisation d'un fichier
class FileSyncStatus {
  final bool existsLocally;
  final String? sha;

  FileSyncStatus({
    required this.existsLocally,
    this.sha,
  });
}

/// Informations détaillées sur un fichier
class FileInfo {
  final String path;
  final String remoteSha;
  final String? localSha;
  final int size;
  final bool isUpToDate;

  FileInfo({
    required this.path,
    required this.remoteSha,
    this.localSha,
    required this.size,
    required this.isUpToDate,
  });
}

/// Résultat de la synchronisation globale
class SyncResult {
  final int success;
  final int failed;
  final int upToDate;
  final List<String> errors;
  final int totalFiles;

  SyncResult({
    required this.success,
    required this.failed,
    required this.upToDate,
    required this.errors,
    required this.totalFiles,
  });

  bool get hasErrors => failed > 0;
  bool get allSuccess => failed == 0;
  
  String get message {
    if (allSuccess) {
      if (upToDate > 0 && success == 0) {
        return '✅ Tous les fichiers sont déjà à jour ($upToDate/$totalFiles)';
      } else if (success > 0) {
        return '✅ $success fichier(s) mis à jour${upToDate > 0 ? ', $upToDate déjà à jour' : ''} ($totalFiles total)';
      }
      return '✅ Tous les fichiers sont à jour ($totalFiles/$totalFiles)';
    } else {
      return '⚠️ ${success + upToDate}/$totalFiles OK - $failed erreur(s)';
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