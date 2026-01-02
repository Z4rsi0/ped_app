import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Pour compute
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de synchronisation des données depuis GitHub
class DataSyncService {
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubOwner = 'Z4rsi0';
  static const String githubRepo = 'ped_app_data';
  static const String githubBranch = 'main';
  
  /// Fichiers "Core" toujours présents
  static const Map<String, String> _staticFiles = {
    'assets/medicaments_pediatrie.json': 'assets/medicaments_pediatrie.json',
    'assets/annuaire.json': 'assets/annuaire.json',
  };

  /// Synchronise tous les fichiers (Statiques + Protocoles dynamiques)
  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    int upToDate = 0;
    List<String> errors = [];

    // 1. Construire la liste complète des fichiers à synchroniser
    Map<String, String> filesToSync = Map.from(_staticFiles);

    // 2. Récupérer la liste dynamique des protocoles depuis GitHub
    if (await hasInternetConnection()) {
      try {
        debugPrint('🔍 Recherche des protocoles sur GitHub...');
        final dynamicProtocols = await _fetchRemoteProtocolsList();
        filesToSync.addAll(dynamicProtocols);
        debugPrint('📄 ${dynamicProtocols.length} protocoles trouvés sur le serveur.');
      } catch (e) {
        debugPrint('⚠️ Impossible de lister les protocoles distants : $e');
        errors.add('Liste protocoles: $e');
        // On continue avec les fichiers statiques et ce qu'on a déjà en local
      }
    }

    // 3. Lancer la synchronisation pour chaque fichier
    for (var entry in filesToSync.entries) {
      try {
        final result = await _downloadFile(entry.key, entry.value);
        if (result == DownloadResult.success) {
          success++;
        } else if (result == DownloadResult.upToDate) {
          upToDate++;
        } else {
          failed++;
          errors.add(entry.key);
        }
      } catch (e) {
        failed++;
        errors.add('${entry.key}: $e');
      }
    }

    // 4. Nettoyage (Optionnel) : Supprimer les protocoles locaux qui n'existent plus sur GitHub
    // (Implémentation basique : on ne supprime rien pour sécurité hors ligne pour l'instant)

    return SyncResult(
      success: success,
      failed: failed,
      upToDate: upToDate,
      errors: errors,
      totalFiles: filesToSync.length,
    );
  }

  /// Récupère la liste des fichiers JSON dans assets/protocoles via l'API GitHub
  static Future<Map<String, String>> _fetchRemoteProtocolsList() async {
    final Map<String, String> protocols = {};
    const protocolPath = 'assets/protocoles';
    
    final apiUrl = '$githubApiBase/$protocolPath?ref=$githubBranch';
    
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    
    final token = dotenv.env['GITHUB_TOKEN'];
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(Uri.parse(apiUrl), headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      for (var item in data) {
        if (item['type'] == 'file' && item['name'].toString().endsWith('.json')) {
          final path = item['path'] as String;
          // Clé locale = Chemin distant pour simplifier
          protocols[path] = path; 
        }
      }
    } else {
      throw Exception('API GitHub erreur ${response.statusCode}');
    }
    
    return protocols;
  }

  static Future<DownloadResult> _downloadFile(String relativePath, String githubPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shaKey = 'sha_$relativePath';
      final localSha = prefs.getString(shaKey);

      final apiUrl = '$githubApiBase/$githubPath?ref=$githubBranch';
      
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
      };
      
      final token = dotenv.env['GITHUB_TOKEN'];
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final apiResponse = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode != 200) return DownloadResult.failed;

      final apiData = json.decode(apiResponse.body);
      final remoteSha = apiData['sha'] as String?;
      final downloadUrl = apiData['download_url'] as String?;

      if (remoteSha == null || downloadUrl == null) return DownloadResult.failed;

      if (localSha == remoteSha) {
        // Vérifier quand même que le fichier existe physiquement
        if (await fileExistsLocally(relativePath)) {
          return DownloadResult.upToDate;
        }
      }

      final contentResponse = await http.get(
        Uri.parse(downloadUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 15));

      if (contentResponse.statusCode != 200) return DownloadResult.failed;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$relativePath');
      
      await file.parent.create(recursive: true);
      await file.writeAsString(contentResponse.body);
      await prefs.setString(shaKey, remoteSha);
      
      return DownloadResult.success;
    } catch (e) {
      debugPrint('❌ Exception _downloadFile ($relativePath): $e');
      return DownloadResult.failed;
    }
  }

  /// Lit un fichier (priorité: local > assets embarqués)
  static Future<String> readFile(String assetPath) async {
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }

    // 1. Essai lecture locale (Données mises à jour)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$assetPath');
      
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lecture locale de $assetPath: $e');
    }

    // 2. Fallback assets embarqués (Données "usine")
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      // Si c'est un fichier dynamique (nouveau protocole), il n'est pas dans les assets
      debugPrint('ℹ️ Fichier non trouvé dans les assets (normal si nouveau protocole): $assetPath');
      throw Exception('Fichier introuvable: $assetPath');
    }
  }

  /// Liste tous les fichiers disponibles localement dans un dossier
  static Future<List<String>> listLocalFiles(String directoryPath) async {
    List<String> files = [];
    
    // 1. Scanner le dossier local (Documents)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localDir = Directory('${dir.path}/$directoryPath');
      
      if (await localDir.exists()) {
        final entities = localDir.listSync();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.json')) {
            // Extraire le nom de fichier
            files.add(entity.uri.pathSegments.last);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur scan local: $e');
    }

    // 2. Scanner les assets (Manifest)
    // C'est plus complexe en Flutter release, mais pour les protocoles dynamiques,
    // on compte principalement sur le dossier local ou une liste connue.
    // Pour l'instant, on se base sur la découverte locale post-sync.
    
    return files.toSet().toList(); // Uniques
  }

  static Future<T> readAndParseJson<T>(
    String assetPath,
    T Function(dynamic json) parser,
  ) async {
    try {
      final jsonString = await readFile(assetPath);
      return await compute((String content) {
        final decoded = jsonDecode(content);
        return parser(decoded);
      }, jsonString);
    } catch (e) {
      debugPrint('❌ Erreur parsing JSON pour $assetPath: $e');
      throw Exception('Impossible de charger les données: $e');
    }
  }

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
  
  static Future<bool> fileExistsLocally(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$assetPath');
    return await file.exists();
  }
}

enum DownloadResult { success, upToDate, failed }

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
  
  String get message {
    if (failed == 0) {
      return '✅ Données à jour';
    } else {
      return '⚠️ Mise à jour partielle ($failed erreurs)';
    }
  }
}