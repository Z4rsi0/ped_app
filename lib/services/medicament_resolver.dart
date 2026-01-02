import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import 'data_sync_service.dart';

class MedicamentResolver {
  static final MedicamentResolver _instance = MedicamentResolver._internal();
  factory MedicamentResolver() => _instance;
  MedicamentResolver._internal();

  List<Medicament>? _medicaments;
  bool _isLoaded = false;

  /// Charge la liste des médicaments via DataSyncService (Parsing Isolé)
  Future<void> loadMedicaments() async {
    if (_isLoaded) return;
    
    try {
      _medicaments = await DataSyncService.readAndParseJson(
        'medicaments_pediatrie.json',
        (jsonList) {
          if (jsonList is List) {
            return jsonList.map((j) => Medicament.fromJson(j)).toList();
          }
          return [];
        },
      );
      _isLoaded = true;
      debugPrint('✅ Résolveur: ${_medicaments!.length} médicaments chargés');
    } catch (e) {
      debugPrint('❌ Erreur chargement resolver: $e');
      rethrow;
    }
  }

  /// Résout un médicament et calcule la posologie
  /// Utilise maintenant le modèle unifié Medicament et DoseCalculator (via Posologie.calculerDose)
  PosologieResolue? resolveMedicament({
    required String nomMedicament,
    required String indication,
    String? voie,
    required double poids,
  }) {
    if (!_isLoaded || _medicaments == null) {
      // Tentative de reload silencieux ou throw
      throw Exception('Médicaments non chargés');
    }

    try {
      // 1. Trouver le médicament (insensible à la casse)
      final medicament = _medicaments!.firstWhere(
        (m) => m.nom.toLowerCase() == nomMedicament.toLowerCase(),
        orElse: () => throw Exception('Médicament introuvable: $nomMedicament'),
      );

      // 2. Trouver l'indication (contient le texte)
      final indicationTrouvee = medicament.indications.firstWhere(
        (i) => i.label.toLowerCase().contains(indication.toLowerCase()),
        orElse: () => throw Exception('Indication introuvable: $indication'),
      );

      // 3. Trouver la posologie (avec voie si spécifiée)
      Posologie posologie;
      if (voie != null && voie.isNotEmpty) {
        posologie = indicationTrouvee.posologies.firstWhere(
          (p) => p.voie.toLowerCase().contains(voie.toLowerCase()),
          orElse: () => indicationTrouvee.posologies.first,
        );
      } else {
        posologie = indicationTrouvee.posologies.first;
      }

      // 4. Calculer la dose (Délégué au modèle -> DoseCalculator)
      final doseCalculee = posologie.calculerDose(poids);

      return PosologieResolue(
        nomMedicament: medicament.nom,
        indication: indicationTrouvee.label,
        voie: posologie.voie,
        dose: doseCalculee,
        preparation: posologie.preparation,
        galenique: medicament.galenique,
        commentaire: medicament.aSavoir, // On peut mapper 'à savoir' comme commentaire
      );
    } catch (e) {
      debugPrint('Erreur resolveMedicament ($nomMedicament): $e');
      return null;
    }
  }
}

class PosologieResolue {
  final String nomMedicament;
  final String indication;
  final String voie;
  final String dose;
  final String preparation;
  final String galenique;
  final String? commentaire;

  PosologieResolue({
    required this.nomMedicament,
    required this.indication,
    required this.voie,
    required this.dose,
    required this.preparation,
    required this.galenique,
    this.commentaire,
  });
}