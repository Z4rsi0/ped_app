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

  List<Protocol> get protocols => _protocols ?? [];
  bool get isLoaded => _isLoaded;

  /// Charge tous les protocoles disponibles (locaux + assets)
  Future<void> loadProtocols() async {
    if (_isLoaded) {
      return;
    }

    try {
      _protocols = [];

      // 1. Découvrir les fichiers de protocoles disponibles localement
      final protocolFiles = await DataSyncService.listLocalFiles('assets/protocoles');
      
      // Si la liste est vide (premier lancement sans internet), ajouter les defaults connus
      if (protocolFiles.isEmpty) {
        protocolFiles.addAll([
          'etat_de_mal_epileptique.json',
          'arret_cardio_respiratoire.json',
        ]);
      }

      debugPrint('📂 Fichiers protocoles détectés: ${protocolFiles.length}');

      // 2. Charger chaque fichier
      for (final filename in protocolFiles) {
        try {
          final protocol = await _loadProtocolFile(filename);
          if (protocol != null) {
            // Éviter les doublons si le fichier est présent dans assets ET local
            if (!_protocols!.any((p) => p.titre == protocol.titre)) {
              _protocols!.add(protocol);
            }
          }
        } catch (e) {
          debugPrint('❌ Erreur chargement protocole $filename: $e');
        }
      }
      
      // Tri alphabétique
      _protocols!.sort((a, b) => a.titre.compareTo(b.titre));

      _isLoaded = true;
      debugPrint('✅ ${_protocols!.length} protocole(s) chargé(s)');
    } catch (e) {
      debugPrint('❌ Erreur chargement protocoles: $e');
      rethrow;
    }
  }

  Future<void> reloadProtocols() async {
    _isLoaded = false;
    _protocols = null;
    await loadProtocols();
  }

  Future<Protocol?> _loadProtocolFile(String filename) async {
    try {
      // Assurer le chemin complet
      final path = filename.startsWith('assets/protocoles/') 
          ? filename 
          : 'assets/protocoles/$filename';

      // Utilisation du parsing optimisé
      return await DataSyncService.readAndParseJson(path, (jsonMap) {
        // Logique de rétrocompatibilité (Ancien format)
        if (jsonMap.containsKey('blocs')) {
          return Protocol.fromJson(jsonMap);
        } else if (jsonMap.containsKey('etapes')) {
          return _convertOldFormat(jsonMap);
        }
        return Protocol.fromJson(jsonMap);
      });
    } catch (e) {
      // Ne pas spammer la console si le fichier n'est pas trouvé (cas des defaults absents)
      return null;
    }
  }

  // ... [Reste du fichier inchangé : _convertOldFormat, findByTitre, search] ...
  
  Protocol _convertOldFormat(Map<String, dynamic> oldJson) {
    // (Copier la méthode _convertOldFormat de votre fichier précédent ici)
    // Pour alléger la réponse, je ne la répète pas si elle n'a pas changé,
    // mais assurez-vous qu'elle est bien dans le fichier final.
    final blocs = <ProtocolBlock>[];
    int ordre = 0;

    final etapes = oldJson['etapes'] as List<dynamic>? ?? [];
    for (final etape in etapes) {
      final etapeMap = etape as Map<String, dynamic>;
      final contenu = <ProtocolBlock>[];
      int sousOrdre = 0;

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

      if (etapeMap['attention'] != null) {
        contenu.add(AlerteBlock(
          ordre: sousOrdre++,
          contenu: etapeMap['attention'],
          niveau: AlerteNiveau.attention,
        ));
      }

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
}