import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';
import 'storage_service.dart';
import '../utils/string_utils.dart';

class DataSyncService {
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubBranch = 'main';
  
  static const String pathMedicaments = 'assets/medicaments_pediatrie.json';
  static const String pathAnnuaire = 'assets/annuaire.json';
  static const String dirProtocoles = 'assets/protocoles'; 
  // NOUVEAU : Dossier Pocus
  static const String dirPocus = 'assets/pocus';

  // Clés pour SharedPreferences
  static const String _prefShaPrefix = 'sha_';

  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    int skipped = 0; 
    List<String> errors = [];
    
    final storage = StorageService();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Vérification réseau
    if (!await hasInternetConnection()) {
      return SyncResult(success: 0, failed: 0, errors: [], isOffline: true);
    }

    debugPrint('🌍 Vérification des mises à jour Cloud...');

    // A. Médicaments
    try {
      final changed = await _syncSingleFile<List<Medicament>>(
        path: pathMedicaments,
        prefs: prefs,
        parser: (json) => (json as List).map((e) => Medicament.fromJson(e)).toList(),
        onSave: (data) => storage.saveMedicaments(data),
      );
      if (changed) success++; else skipped++;
    } catch (e) {
      failed++;
      errors.add('Médicaments: $e');
      debugPrint('❌ Erreur Médicaments: $e');
    }

    // B. Annuaire
    try {
      final changed = await _syncSingleFile<Annuaire>(
        path: pathAnnuaire,
        prefs: prefs,
        parser: (json) => Annuaire.fromJson(json),
        onSave: (data) => storage.saveAnnuaire(data),
      );
      if (changed) success++; else skipped++;
    } catch (e) {
      failed++;
      errors.add('Annuaire: $e');
      debugPrint('❌ Erreur Annuaire: $e');
    }

    // C. Protocoles (Dossier)
    try {
      final protoResult = await _syncFolderFromGithub(
        storage: storage,
        prefs: prefs,
        directory: dirProtocoles,
        currentList: storage.getProtocols(),
        onSave: (list) => storage.saveProtocols(list),
        label: 'Protocoles',
      );
      success += protoResult.downloaded;
      skipped += protoResult.skipped;
    } catch (e) {
      failed++;
      errors.add('Protocoles: $e');
      debugPrint('❌ Erreur Protocoles: $e');
    }

    // D. POCUS (Nouveau Dossier)
    try {
      final pocusResult = await _syncFolderFromGithub(
        storage: storage,
        prefs: prefs,
        directory: dirPocus,
        currentList: storage.getPocusProtocols(),
        onSave: (list) => storage.savePocusProtocols(list),
        label: 'Pocus',
      );
      success += pocusResult.downloaded;
      skipped += pocusResult.skipped;
    } catch (e) {
      failed++;
      errors.add('Pocus: $e');
      debugPrint('❌ Erreur Pocus: $e');
    }

    debugPrint('✅ Synchro terminée : $success téléchargés, $skipped à jour (cache), $failed échecs.');
    return SyncResult(success: success, failed: failed, errors: errors);
  }

  /// Synchronise un fichier unique
  static Future<bool> _syncSingleFile<T>({
    required String path,
    required SharedPreferences prefs,
    required T Function(dynamic) parser,
    required Function(T) onSave,
  }) async {
    final metadata = await _getRemoteMetadata(path);
    if (metadata == null) return false;

    final remoteSha = metadata['sha'];
    final localSha = prefs.getString('$_prefShaPrefix$path');

    if (localSha == remoteSha) {
      return false;
    }

    debugPrint('⬇️ Mise à jour de $path détectée...');
    final downloadUrl = metadata['download_url'];
    final content = await _downloadContent(downloadUrl);
    
    if (content != null) {
      final data = await compute((String body) {
        final json = jsonDecode(body);
        return parser(json);
      }, content);
      
      await onSave(data);
      await prefs.setString('$_prefShaPrefix$path', remoteSha);
      return true;
    }
    return false;
  }

  /// Méthode GÉNÉRIQUE pour synchroniser un dossier complet (Protocoles ou Pocus)
  static Future<({int downloaded, int skipped})> _syncFolderFromGithub({
    required StorageService storage,
    required SharedPreferences prefs,
    required String directory,
    required List<Protocol> currentList,
    required Function(List<Protocol>) onSave,
    required String label,
  }) async {
    int downloadedCount = 0;
    int skippedCount = 0;

    // 1. Lister les fichiers distants
    final url = '$githubApiBase/$directory?ref=$githubBranch';
    final headers = _getHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers);
    
    // Si le dossier n'existe pas encore sur le repo (ex: assets/pocus vide), on ignore silencieusement
    if (response.statusCode == 404) {
      debugPrint('⚠️ Dossier introuvable sur GitHub : $directory (Ignoré)');
      return (downloaded: 0, skipped: 0);
    }
    
    if (response.statusCode != 200) throw Exception('Impossible de lister $label ($directory)');

    final List<dynamic> remoteFiles = jsonDecode(response.body);
    
    // 2. Préparer la Map locale pour le patch
    final Map<String, Protocol> itemsMap = {
      for (var p in currentList) StringUtils.normalize(p.titre): p
    };

    bool listHasChanged = false;

    // 3. Boucle sur les fichiers
    for (var file in remoteFiles) {
      final name = file['name'].toString();
      if (!name.endsWith('.json')) continue;

      final remoteSha = file['sha'];
      final downloadUrl = file['download_url'];
      final localShaKey = '$_prefShaPrefix$directory/$name'; // Clé unique par dossier/fichier
      final localSha = prefs.getString(localShaKey);

      if (localSha == remoteSha) {
        skippedCount++;
      } else {
        debugPrint('⬇️ Téléchargement $label : $name');
        if (downloadUrl != null) {
          try {
             final content = await _downloadContent(downloadUrl);
             if (content != null) {
               final newProtocol = await compute(_parseProtocol, content);
               
               // Mise à jour de la Map
               itemsMap[StringUtils.normalize(newProtocol.titre)] = newProtocol;
               
               // Mise à jour du SHA
               await prefs.setString(localShaKey, remoteSha);
               
               downloadedCount++;
               listHasChanged = true;
             }
          } catch (e) {
            debugPrint('⚠️ Erreur download $name: $e');
          }
        }
      }
    }

    // 4. Sauvegarde Hive
    if (listHasChanged) {
      await onSave(itemsMap.values.toList());
    } else if (currentList.isEmpty && skippedCount > 0) {
      // Cas limite : Cache incoherent
      debugPrint('⚠️ Incohérence Cache/Hive pour $label. Reset SHA.');
      for (var file in remoteFiles) {
        await prefs.remove('$_prefShaPrefix$directory/${file['name']}');
      }
      // Retry récursif unique
      return _syncFolderFromGithub(
        storage: storage, 
        prefs: prefs, 
        directory: directory, 
        currentList: currentList, 
        onSave: onSave, 
        label: label
      );
    }

    return (downloaded: downloadedCount, skipped: skippedCount);
  }

  // --- HELPERS ---

  static Map<String, String> _getHeaders() {
    final headers = {'Accept': 'application/vnd.github.v3+json'};
    final token = dotenv.env['GITHUB_TOKEN'];
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<Map<String, dynamic>?> _getRemoteMetadata(String path) async {
    final url = '$githubApiBase/$path?ref=$githubBranch';
    try {
      final response = await http.get(Uri.parse(url), headers: _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Erreur metadata $path: $e');
    }
    return null;
  }

  static Future<String?> _downloadContent(String url) async {
    try {
      final headers = _getHeaders();
      headers['Accept'] = 'application/vnd.github.v3.raw'; 
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Erreur download content: $e');
    }
    return null;
  }

  static Protocol _parseProtocol(String source) => Protocol.fromJson(jsonDecode(source));

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://8.8.8.8')).timeout(const Duration(seconds: 2));
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
  final bool isOffline;

  SyncResult({
    required this.success, 
    required this.failed, 
    required this.errors,
    this.isOffline = false,
  });
  
  bool get hasErrors => failed > 0;
  String get message {
    if (isOffline) return 'Mode hors ligne';
    if (success == 0 && failed == 0) return 'Données à jour';
    if (failed == 0) return 'Mise à jour effectuée ($success fichiers)';
    return 'Mise à jour partielle ($failed erreurs)';
  }
}