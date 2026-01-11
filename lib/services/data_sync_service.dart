import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Nécessaire pour stocker les SHA
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';
import 'storage_service.dart';
import '../utils/string_utils.dart'; // Pour normaliser les titres pour la comparaison

class DataSyncService {
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubBranch = 'main';
  
  static const String pathMedicaments = 'assets/medicaments_pediatrie.json';
  static const String pathAnnuaire = 'assets/annuaire.json';
  static const String dirProtocoles = 'assets/protocoles'; 

  // Clés pour SharedPreferences
  static const String _prefShaPrefix = 'sha_';

  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    int skipped = 0; // Pour compter ce qu'on n'a pas eu besoin de télécharger
    List<String> errors = [];
    
    final storage = StorageService();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Vérification réseau
    if (!await hasInternetConnection()) {
      return SyncResult(success: 0, failed: 0, errors: [], isOffline: true);
    }

    debugPrint('🌍 Vérification des mises à jour Cloud...');

    // A. Médicaments (Fichier unique)
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

    // B. Annuaire (Fichier unique)
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

    // C. Protocoles (Dossier complet)
    try {
      final protoResult = await _syncProtocolsFromGithub(storage, prefs);
      success += protoResult.downloaded;
      skipped += protoResult.skipped;
    } catch (e) {
      failed++;
      errors.add('Protocoles: $e');
      debugPrint('❌ Erreur Protocoles: $e');
    }

    debugPrint('✅ Synchro terminée : $success téléchargés, $skipped à jour (cache), $failed échecs.');
    return SyncResult(success: success, failed: failed, errors: errors);
  }

  /// Synchronise un fichier unique seulement si le SHA a changé
  /// Retourne true si un téléchargement a eu lieu, false sinon
  static Future<bool> _syncSingleFile<T>({
    required String path,
    required SharedPreferences prefs,
    required T Function(dynamic) parser,
    required Function(T) onSave,
  }) async {
    // 1. Récupérer les métadonnées (SHA)
    final metadata = await _getRemoteMetadata(path);
    if (metadata == null) return false;

    final remoteSha = metadata['sha'];
    final localSha = prefs.getString('$_prefShaPrefix$path');

    // 2. Comparer
    if (localSha == remoteSha) {
      debugPrint('⚡ $path est à jour (SHA identique). Pas de téléchargement.');
      return false;
    }

    // 3. Télécharger le contenu (car différent)
    debugPrint('⬇️ Mise à jour de $path détectée...');
    final downloadUrl = metadata['download_url'];
    final content = await _downloadContent(downloadUrl);
    
    if (content != null) {
      // 4. Parser et Sauvegarder
      final data = await compute((String body) {
        final json = jsonDecode(body);
        return parser(json);
      }, content);
      
      await onSave(data);

      // 5. Mettre à jour le SHA local
      await prefs.setString('$_prefShaPrefix$path', remoteSha);
      return true;
    }
    return false;
  }

  /// Logique intelligente pour les protocoles (Dossier)
  static Future<({int downloaded, int skipped})> _syncProtocolsFromGithub(
    StorageService storage, 
    SharedPreferences prefs
  ) async {
    int downloadedCount = 0;
    int skippedCount = 0;

    // 1. Récupérer la liste des fichiers distants
    final url = '$githubApiBase/$dirProtocoles?ref=$githubBranch';
    final headers = _getHeaders();
    
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode != 200) throw Exception('Impossible de lister les protocoles');

    final List<dynamic> remoteFiles = jsonDecode(response.body);
    
    // 2. Charger les protocoles locaux actuels pour faire un "Patch"
    // (Car StorageService.saveProtocols écrase tout, donc on doit garder ceux qui ne changent pas)
    final List<Protocol> currentProtocols = storage.getProtocols();
    final Map<String, Protocol> protocolMap = {
      for (var p in currentProtocols) StringUtils.normalize(p.titre): p
    };

    bool listHasChanged = false;

    // 3. Itérer sur les fichiers distants
    for (var file in remoteFiles) {
      final name = file['name'].toString();
      if (!name.endsWith('.json')) continue;

      final remoteSha = file['sha'];
      final downloadUrl = file['download_url'];
      final localShaKey = '$_prefShaPrefix$dirProtocoles/$name';
      final localSha = prefs.getString(localShaKey);

      // --- LOGIQUE DE COMPARAISON ---
      if (localSha == remoteSha) {
        // Le fichier n'a pas changé sur le serveur
        skippedCount++;
      } else {
        // Le fichier est nouveau ou modifié
        debugPrint('⬇️ Téléchargement protocole : $name');
        if (downloadUrl != null) {
          try {
             final content = await _downloadContent(downloadUrl);
             if (content != null) {
               final newProtocol = await compute(_parseProtocol, content);
               
               // Mise à jour de la Map (remplace l'ancien ou ajoute le nouveau)
               protocolMap[StringUtils.normalize(newProtocol.titre)] = newProtocol;
               
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

    // 4. Sauvegarder seulement si nécessaire
    // Si on a téléchargé au moins un fichier, la liste est modifiée, on sauvegarde tout.
    // (Note: Si un fichier est supprimé sur le serveur, il restera en local avec cette logique simple. 
    // Pour l'instant c'est plus sûr pour éviter les pertes accidentelles).
    if (listHasChanged) {
      await storage.saveProtocols(protocolMap.values.toList());
    } else if (currentProtocols.isEmpty && skippedCount > 0) {
      // Cas limite : On a des SHA en cache mais Hive est vide (ex: Clear data sans clear prefs)
      // On force le re-téléchargement au prochain lancement en effaçant les prefs
      debugPrint('⚠️ Incohérence Cache/Hive détectée. Reset des SHA pour force update.');
      for (var file in remoteFiles) {
        await prefs.remove('$_prefShaPrefix$dirProtocoles/${file['name']}');
      }
      // On relance une synchro récursive (une seule fois)
      return _syncProtocolsFromGithub(storage, prefs);
    }

    return (downloaded: downloadedCount, skipped: skippedCount);
  }

  // --- HELPERS ---

  static Map<String, String> _getHeaders() {
    final headers = {'Accept': 'application/vnd.github.v3+json'}; // On veut le JSON metadata par défaut
    final token = dotenv.env['GITHUB_TOKEN'];
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Récupère les métadonnées d'un fichier (SHA, size, download_url) sans le contenu
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

  /// Télécharge le contenu brut (Raw)
  static Future<String?> _downloadContent(String url) async {
    try {
      // On utilise v3.raw pour avoir le contenu direct
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
      // Ping léger vers Google DNS (rapide et fiable)
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