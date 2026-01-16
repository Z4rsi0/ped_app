// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, compute, debugPrint;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';
import '../models/toxic_agent.dart'; // Import du modèle ToxicAgent
import 'storage_service.dart';
import '../utils/string_utils.dart';

class DataSyncService {
  // --- CONFIGURATION ---
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubBranch = 'main';
  
  // Chemins distants GitHub
  static const String pathMedicaments = 'assets/medicaments_pediatrie.json';
  static const String pathAnnuaire = 'assets/annuaire.json';
  static const String pathToxiques = 'assets/toxiques.json'; // NOUVEAU
  
  static const String dirProtocoles = 'assets/protocoles'; 
  static const String dirPocus = 'assets/pocus';

  // URL relative pour le Web
  static const String webBasePath = 'data';

  static const String _prefShaPrefix = 'sha_';

  /// Point d'entrée principal
  static Future<SyncResult> syncAllData() async {
    if (kIsWeb) {
      debugPrint('🌐 Mode Web : Chargement via HTTP local...');
      return await _loadFromWebFolder();
    } else {
      debugPrint('📱 Mode Mobile : Synchronisation GitHub...');
      return await _syncFromGithub();
    }
  }

  // ===========================================================================
  // 🟢 MODE WEB (Lecture via HTTP relatif + listing.json)
  // ===========================================================================

  static Future<SyncResult> _loadFromWebFolder() async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];
    final storage = StorageService();

    Future<dynamic> loadLocalJson(String path) async {
      final url = Uri.parse('$webBasePath/$path');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      throw Exception("Fichier introuvable ($path) : ${response.statusCode}");
    }

    // 1. Médicaments
    try {
      final jsonList = await loadLocalJson('medicaments_pediatrie.json');
      final list = (jsonList as List).map((e) => Medicament.fromJson(e)).toList();
      await storage.saveMedicaments(list);
      success++;
    } catch (e) {
      failed++;
      errors.add("Web Medicaments: $e");
    }

    // 2. Annuaire
    try {
      final jsonData = await loadLocalJson('annuaire.json');
      await storage.saveAnnuaire(Annuaire.fromJson(jsonData));
      success++;
    } catch (e) {
      failed++;
      errors.add("Web Annuaire: $e");
    }

    // 3. NOUVEAU : Toxiques
    try {
      final jsonList = await loadLocalJson('toxiques.json');
      final list = (jsonList as List).map((e) => ToxicAgent.fromJson(e)).toList();
      await storage.saveToxicAgents(list);
      success++;
    } catch (e) {
      // Pas critique pour l'instant si le fichier n'est pas encore là
      debugPrint("Info: Pas de toxiques.json trouvé en Web (ou erreur format)");
      errors.add("Web Toxiques: $e");
    }

    // 4. Listing pour les dossiers
    Map<String, dynamic> listing = {};
    try {
      listing = await loadLocalJson('listing.json');
    } catch (e) {
      errors.add("listing.json manquant !");
    }

    Future<int> loadFolder(String folderKey, Function(List<Protocol>) onSave) async {
      if (!listing.containsKey(folderKey)) return 0;
      List<dynamic> files = listing[folderKey];
      List<Protocol> protocols = [];
      for (var fileName in files) {
        try {
          final jsonP = await loadLocalJson('$folderKey/$fileName');
          protocols.add(Protocol.fromJson(jsonP));
        } catch (e) { debugPrint("⚠️ Erreur $fileName: $e"); }
      }
      if (protocols.isNotEmpty) await onSave(protocols);
      return protocols.length;
    }

    try {
      success += await loadFolder('protocoles', (l) => storage.saveProtocols(l));
    } catch (e) { failed++; }

    try {
      success += await loadFolder('pocus', (l) => storage.savePocusProtocols(l));
    } catch (e) { failed++; }

    return SyncResult(success: success, failed: failed, errors: errors, isOffline: true);
  }

  // ===========================================================================
  // 🟠 MODE MOBILE (GitHub)
  // ===========================================================================

  static Future<SyncResult> _syncFromGithub() async {
    int success = 0;
    int failed = 0;
    int skipped = 0; 
    List<String> errors = [];
    
    final storage = StorageService();
    final prefs = await SharedPreferences.getInstance();
    
    if (!await hasInternetConnection()) {
      return SyncResult(success: 0, failed: 0, errors: [], isOffline: true);
    }

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
    }

    // C. NOUVEAU : Toxiques
    try {
      final changed = await _syncSingleFile<List<ToxicAgent>>(
        path: pathToxiques,
        prefs: prefs,
        parser: (json) => (json as List).map((e) => ToxicAgent.fromJson(e)).toList(),
        onSave: (data) => storage.saveToxicAgents(data),
      );
      if (changed) success++; else skipped++;
    } catch (e) {
      failed++;
      errors.add('Toxiques: $e');
    }

    // D. Dossiers (Protocoles & Pocus)
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
    }

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
    }

    return SyncResult(success: success, failed: failed, errors: errors);
  }

  // --- HELPERS (Inchangés) ---
  
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

    if (localSha == remoteSha) return false;

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
    final url = '$githubApiBase/$directory?ref=$githubBranch';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    
    if (response.statusCode == 404) return (downloaded: 0, skipped: 0);
    if (response.statusCode != 200) throw Exception('Erreur API Github');

    final List<dynamic> remoteFiles = jsonDecode(response.body);
    final Map<String, Protocol> itemsMap = {
      for (var p in currentList) StringUtils.normalize(p.titre): p
    };

    bool listHasChanged = false;

    for (var file in remoteFiles) {
      final name = file['name'].toString();
      if (!name.endsWith('.json')) continue;

      final remoteSha = file['sha'];
      final downloadUrl = file['download_url'];
      final localShaKey = '$_prefShaPrefix$directory/$name';
      final localSha = prefs.getString(localShaKey);

      if (localSha == remoteSha) {
        skippedCount++;
      } else {
        if (downloadUrl != null) {
          try {
             final content = await _downloadContent(downloadUrl);
             if (content != null) {
               final newProtocol = await compute(_parseProtocol, content);
               itemsMap[StringUtils.normalize(newProtocol.titre)] = newProtocol;
               await prefs.setString(localShaKey, remoteSha);
               downloadedCount++;
               listHasChanged = true;
             }
          } catch (e) { debugPrint('⚠️ Erreur download $name: $e'); }
        }
      }
    }

    if (listHasChanged) await onSave(itemsMap.values.toList());
    return (downloaded: downloadedCount, skipped: skippedCount);
  }

  static Map<String, String> _getHeaders() {
    final headers = {'Accept': 'application/vnd.github.v3+json'};
    final token = dotenv.env['GITHUB_TOKEN'];
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<Map<String, dynamic>?> _getRemoteMetadata(String path) async {
    try {
      final response = await http.get(Uri.parse('$githubApiBase/$path?ref=$githubBranch'), headers: _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint('$e'); }
    return null;
  }

  static Future<String?> _downloadContent(String url) async {
    try {
      final headers = _getHeaders();
      headers['Accept'] = 'application/vnd.github.v3.raw'; 
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) return utf8.decode(response.bodyBytes);
    } catch (e) { debugPrint('$e'); }
    return null;
  }

  static Protocol _parseProtocol(String source) => Protocol.fromJson(jsonDecode(source));

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://8.8.8.8')).timeout(const Duration(seconds: 2));
      return result.statusCode == 200;
    } catch (e) { return false; }
  }
}

class SyncResult {
  final int success;
  final int failed;
  final List<String> errors;
  final bool isOffline;
  SyncResult({required this.success, required this.failed, required this.errors, this.isOffline = false});
  bool get hasErrors => failed > 0;
}