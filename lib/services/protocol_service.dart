import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import 'data_sync_service.dart';

/// Service de gestion des protocoles
class ProtocolService {
  static final ProtocolService _instance = ProtocolService._internal();
  factory ProtocolService() => _instance;
  ProtocolService._internal();

  List<Protocol>? _protocols;
  bool _isLoaded = false;

  /// Liste des protocoles chargés
  List<Protocol> get protocols => _protocols ?? [];
  bool get isLoaded => _isLoaded;

  /// Charge tous les protocoles depuis les fichiers JSON
  Future<void> loadProtocols() async {
    if (_isLoaded) {
      debugPrint('📋 Protocoles déjà chargés (${_protocols?.length ?? 0})');
      return;
    }

    try {
      _protocols = [];

      // Liste des fichiers de protocoles connus
      final protocolFiles = await _getProtocolFiles();

      for (final filename in protocolFiles) {
        try {
          final protocol = await _loadProtocolFile(filename);
          if (protocol != null) {
            _protocols!.add(protocol);
            debugPrint('✅ Protocole chargé: ${protocol.titre}');
          }
        } catch (e) {
          debugPrint('❌ Erreur chargement protocole $filename: $e');
        }
      }

      _isLoaded = true;
      debugPrint('✅ ${_protocols!.length} protocole(s) chargé(s)');
    } catch (e) {
      debugPrint('❌ Erreur chargement protocoles: $e');
      rethrow;
    }
  }

  /// Recharge tous les protocoles
  Future<void> reloadProtocols() async {
    _isLoaded = false;
    _protocols = null;
    await loadProtocols();
  }

  /// Obtient la liste des fichiers de protocoles
  Future<List<String>> _getProtocolFiles() async {
    // Liste statique pour l'instant - peut être rendue dynamique via GitHub API
    return [
      'etat_de_mal_epileptique',
      'arret_cardio_respiratoire',
    ];
  }

  /// Charge un fichier protocole individuel
  Future<Protocol?> _loadProtocolFile(String filename) async {
    try {
      final data = await DataSyncService.readFile(
          'assets/protocoles/$filename.json');
      final jsonData = json.decode(data) as Map<String, dynamic>;

      // Vérifier si c'est l'ancien format ou le nouveau
      if (jsonData.containsKey('blocs')) {
        // Nouveau format
        return Protocol.fromJson(jsonData);
      } else if (jsonData.containsKey('etapes')) {
        // Ancien format - conversion automatique
        return _convertOldFormat(jsonData);
      }

      return Protocol.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Erreur lecture protocole $filename: $e');
      return null;
    }
  }

  /// Convertit l'ancien format de protocole vers le nouveau
  Protocol _convertOldFormat(Map<String, dynamic> oldJson) {
    final blocs = <ProtocolBlock>[];
    int ordre = 0;

    final etapes = oldJson['etapes'] as List<dynamic>? ?? [];
    for (final etape in etapes) {
      final etapeMap = etape as Map<String, dynamic>;
      final contenu = <ProtocolBlock>[];
      int sousOrdre = 0;

      // Convertir les éléments de l'étape
      final elements = etapeMap['elements'] as List<dynamic>? ?? [];
      for (final element in elements) {
        final elemMap = element as Map<String, dynamic>;
        final elemType = elemMap['type'] as String? ?? 'texte';

        if (elemType == 'texte') {
          contenu.add(TexteBlock(
            ordre: sousOrdre++,
            contenu: elemMap['texte'] ?? '',
          ));
        } else if (elemType == 'medicament') {
          final medRef = elemMap['medicament'] as Map<String, dynamic>?;
          if (medRef != null) {
            contenu.add(MedicamentBlock(
              ordre: sousOrdre++,
              nomMedicament: medRef['nom'] ?? '',
              indication: medRef['indication'] ?? '',
              voie: medRef['voie'],
            ));
          }
        }
      }

      // Ajouter une alerte si présente
      if (etapeMap['attention'] != null) {
        contenu.add(AlerteBlock(
          ordre: sousOrdre++,
          contenu: etapeMap['attention'],
          niveau: AlerteNiveau.attention,
        ));
      }

      // Créer la section
      blocs.add(SectionBlock(
        ordre: ordre++,
        titre: etapeMap['titre'] ?? 'Étape ${ordre}',
        temps: etapeMap['temps'],
        initialementOuvert: false,
        contenu: contenu,
      ));
    }

    return Protocol(
      titre: oldJson['nom'] ?? '',
      description: oldJson['description'] ?? '',
      blocs: blocs,
    );
  }

  /// Recherche un protocole par son titre
  Protocol? findByTitre(String titre) {
    if (!_isLoaded || _protocols == null) return null;
    try {
      return _protocols!.firstWhere(
        (p) => p.titre.toLowerCase() == titre.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Recherche des protocoles par mot-clé
  List<Protocol> search(String query) {
    if (!_isLoaded || _protocols == null) return [];
    final queryLower = query.toLowerCase();
    return _protocols!.where((p) {
      return p.titre.toLowerCase().contains(queryLower) ||
          p.description.toLowerCase().contains(queryLower);
    }).toList();
  }
}