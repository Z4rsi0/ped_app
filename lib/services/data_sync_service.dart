import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';
import 'storage_service.dart';

class DataSyncService {
  static const String githubApiBase = 'https://api.github.com/repos/Z4rsi0/ped_app_data/contents';
  static const String githubBranch = 'main';
  
  // Chemins GitHub
  static const String pathMedicaments = 'medicaments_pediatrie.json';
  static const String pathAnnuaire = 'annuaire.json';
  static const String dirProtocoles = 'protocoles'; 

  /// Stratégie "Online-First" : On tente GitHub, on stocke dans Hive.
  static Future<SyncResult> syncAllData() async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];
    
    final storage = StorageService();
    
    // 1. Vérification réseau
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: 0, 
        failed: 0, 
        errors: [], 
        isOffline: true
      );
    }

    debugPrint('🌍 Connexion détectée, synchronisation Cloud...');

    // A. Médicaments (Fichier unique)
    try {
      final meds = await _fetchAndParse<List<Medicament>>(
        pathMedicaments, 
        (json) => (json as List).map((e) => Medicament.fromJson(e)).toList()
      );
      if (meds != null) {
        await storage.saveMedicaments(meds);
        success++;
      }
    } catch (e) {
      failed++;
      errors.add('Médicaments: $e');
    }

    // B. Annuaire (Fichier unique)
    try {
      final annuaire = await _fetchAndParse<Annuaire>(
        pathAnnuaire,
        (json) => Annuaire.fromJson(json),
      );
      if (annuaire != null) {
        await storage.saveAnnuaire(annuaire);
        success++;
      }
    } catch (e) {
      failed++;
      errors.add('Annuaire: $e');
    }

    // C. Protocoles (Dossier dynamique sur GitHub)
    try {
      final protocols = await _syncProtocolsFromGithub();
      if (protocols.isNotEmpty) {
        await storage.saveProtocols(protocols);
        success++;
      }
    } catch (e) {
      failed++;
      errors.add('Protocoles: $e');
    }

    return SyncResult(success: success, failed: failed, errors: errors);
  }

  // --- LOGIQUE GITHUB (inchangée) ---

  static Future<T?> _fetchAndParse<T>(String path, T Function(dynamic) parser) async {
    try {
      final url = '$githubApiBase/$path?ref=$githubBranch';
      final headers = {'Accept': 'application/vnd.github.v3.raw'}; 
      
      final token = dotenv.env['GITHUB_TOKEN'];
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        return await compute((String body) {
          final json = jsonDecode(body);
          return parser(json);
        }, response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur Fetch $path: $e');
      rethrow;
    }
  }

  static Future<List<Protocol>> _syncProtocolsFromGithub() async {
    final List<Protocol> protocols = [];
    
    final url = '$githubApiBase/$dirProtocoles?ref=$githubBranch';
    final headers = {'Accept': 'application/vnd.github.v3+json'};
    final token = dotenv.env['GITHUB_TOKEN'];
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> files = jsonDecode(response.body);
      
      for (var file in files) {
        if (file['name'].toString().endsWith('.json')) {
          final downloadUrl = file['download_url'];
          if (downloadUrl != null) {
            try {
               final pResponse = await http.get(Uri.parse(downloadUrl));
               if (pResponse.statusCode == 200) {
                 final protocol = await compute(_parseProtocol, pResponse.body);
                 protocols.add(protocol);
               }
            } catch (e) {
              debugPrint('⚠️ Erreur download ${file['name']}: $e');
            }
          }
        }
      }
    }
    return protocols;
  }

  // --- PARSERS ---
  static Protocol _parseProtocol(String source) => Protocol.fromJson(jsonDecode(source));

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 3));
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
    if (isOffline) return 'Mode hors ligne (Données locales)';
    if (failed == 0) return '✅ Données à jour';
    return '⚠️ Mise à jour partielle ($failed erreurs)';
  }
}