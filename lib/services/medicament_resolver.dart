import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import 'storage_service.dart';

class MedicamentResolver {
  static final MedicamentResolver _instance = MedicamentResolver._internal();
  factory MedicamentResolver() => _instance;
  MedicamentResolver._internal();

  final StorageService _storage = StorageService();

  /// Ancienne méthode de chargement - Obsolète car Hive charge tout au démarrage.
  /// On la garde vide pour compatibilité si du code l'appelle encore, 
  /// mais elle ne fait rien.
  Future<void> loadMedicaments() async {
    // No-op : Géré par StorageService.init() dans le main.dart
    return;
  }

  /// Résout un médicament et calcule la posologie
  /// Recherche directe dans la base de données locale (Hive)
  PosologieResolue? resolveMedicament({
    required String nomMedicament,
    required String indication,
    String? voie,
    required double poids,
  }) {
    // 1. Récupérer la liste depuis le stockage
    final medicaments = _storage.getMedicaments();
    
    if (medicaments.isEmpty) {
      debugPrint('⚠️ Aucune donnée médicament disponible pour le calcul.');
      return null;
    }

    try {
      // 2. Trouver le médicament (insensible à la casse)
      final medicament = medicaments.firstWhere(
        (m) => m.nom.toLowerCase() == nomMedicament.toLowerCase(),
        orElse: () => throw Exception('Médicament introuvable: $nomMedicament'),
      );

      // 3. Trouver l'indication (contient le texte)
      final indicationTrouvee = medicament.indications.firstWhere(
        (i) => i.label.toLowerCase().contains(indication.toLowerCase()),
        orElse: () => throw Exception('Indication introuvable: $indication'),
      );

      // 4. Trouver la posologie (avec voie si spécifiée)
      Posologie posologie;
      if (voie != null && voie.isNotEmpty) {
        posologie = indicationTrouvee.posologies.firstWhere(
          (p) => p.voie.toLowerCase().contains(voie.toLowerCase()),
          orElse: () => indicationTrouvee.posologies.first,
        );
      } else {
        posologie = indicationTrouvee.posologies.first;
      }

      // 5. Calculer la dose (Délégué au modèle -> DoseCalculator)
      final doseCalculee = posologie.calculerDose(poids);

      return PosologieResolue(
        nomMedicament: medicament.nom,
        indication: indicationTrouvee.label,
        voie: posologie.voie,
        dose: doseCalculee,
        preparation: posologie.preparation,
        galenique: medicament.galenique,
        commentaire: medicament.aSavoir, // On mappe 'à savoir' comme commentaire technique
      );
    } catch (e) {
      debugPrint('⚠️ Erreur resolveMedicament ($nomMedicament): $e');
      return PosologieResolue(
        nomMedicament: nomMedicament, 
        indication: indication, 
        voie: voie ?? '?', 
        dose: "Erreur de calcul", 
        preparation: "", 
        galenique: "",
        commentaire: "Donnée introuvable ou calcul impossible"
      );
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