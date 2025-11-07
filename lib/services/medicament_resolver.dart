import 'dart:convert';
import 'package:flutter/material.dart';
import 'data_sync_service.dart';

class MedicamentResolver {
  static final MedicamentResolver _instance = MedicamentResolver._internal();
  factory MedicamentResolver() => _instance;
  MedicamentResolver._internal();

  List<MedicamentData>? _medicaments;
  bool _isLoaded = false;

  /// Charge la liste des médicaments depuis le fichier JSON
  Future<void> loadMedicaments() async {
    if (_isLoaded) {
      debugPrint('📋 Médicaments déjà chargés');
      return;
    }
    
    try {
      // Lecture avec préfixe assets/
      final data = await DataSyncService.readFile('assets/medicaments_pediatrie.json');
      final List<dynamic> jsonList = json.decode(data);
      _medicaments = jsonList.map((json) => MedicamentData.fromJson(json)).toList();
      _isLoaded = true;
      debugPrint('✅ ${_medicaments!.length} médicaments chargés');
    } catch (e) {
      debugPrint('❌ Erreur chargement médicaments: $e');
      rethrow;
    }
  }

  /// Résout un médicament et calcule la posologie
  PosologieResolue? resolveMedicament({
    required String nomMedicament,
    required String indication,
    String? voie,
    required double poids,
  }) {
    if (!_isLoaded || _medicaments == null) {
      throw Exception('Médicaments non chargés - Appeler loadMedicaments() d\'abord');
    }

    // Trouver le médicament
    final medicament = _medicaments!.firstWhere(
      (m) => m.nom.toLowerCase() == nomMedicament.toLowerCase(),
      orElse: () => throw Exception('Médicament "$nomMedicament" non trouvé'),
    );

    // Trouver l'indication
    final indicationTrouvee = medicament.indications.firstWhere(
      (i) => i.label.toLowerCase().contains(indication.toLowerCase()),
      orElse: () => throw Exception('Indication "$indication" non trouvée pour $nomMedicament'),
    );

    // Trouver la posologie (avec voie si spécifiée)
    PosologieData posologie;
    if (voie != null) {
      posologie = indicationTrouvee.posologies.firstWhere(
        (p) => p.voie.toLowerCase().contains(voie.toLowerCase()),
        orElse: () => indicationTrouvee.posologies.first,
      );
    } else {
      posologie = indicationTrouvee.posologies.first;
    }

    // Calculer la dose
    final doseCalculee = posologie.calculerDose(poids);

    return PosologieResolue(
      nomMedicament: medicament.nom,
      indication: indicationTrouvee.label,
      voie: posologie.voie,
      dose: doseCalculee,
      preparation: posologie.preparation,
      galenique: medicament.galenique,
    );
  }
}

class PosologieResolue {
  final String nomMedicament;
  final String indication;
  final String voie;
  final String dose;
  final String preparation;
  final String galenique;

  PosologieResolue({
    required this.nomMedicament,
    required this.indication,
    required this.voie,
    required this.dose,
    required this.preparation,
    required this.galenique,
  });
}

// Modèles simplifiés pour le resolver
class MedicamentData {
  final String nom;
  final String galenique;
  final List<IndicationData> indications;

  MedicamentData({
    required this.nom,
    required this.galenique,
    required this.indications,
  });

  factory MedicamentData.fromJson(Map<String, dynamic> json) {
    return MedicamentData(
      nom: json['nom'] ?? '',
      galenique: json['galenique'] ?? '',
      indications: (json['indications'] as List?)
          ?.map((i) => IndicationData.fromJson(i))
          .toList() ?? [],
    );
  }
}

class IndicationData {
  final String label;
  final List<PosologieData> posologies;

  IndicationData({required this.label, required this.posologies});

  factory IndicationData.fromJson(Map<String, dynamic> json) {
    return IndicationData(
      label: json['label'] ?? '',
      posologies: (json['posologies'] as List?)
          ?.map((p) => PosologieData.fromJson(p))
          .toList() ?? [],
    );
  }
}

class TrancheData {
  final double? poidsMin;
  final double? poidsMax;
  final double doseKg;
  final double? doseKgMin;
  final double? doseKgMax;

  TrancheData({
    this.poidsMin,
    this.poidsMax,
    required this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
  });

  factory TrancheData.fromJson(Map<String, dynamic> json) {
    return TrancheData(
      poidsMin: json['poidsMin']?.toDouble(),
      poidsMax: json['poidsMax']?.toDouble(),
      doseKg: (json['doseKg'] ?? 0).toDouble(),
      doseKgMin: json['doseKgMin']?.toDouble(),
      doseKgMax: json['doseKgMax']?.toDouble(),
    );
  }

  bool appliqueAPoids(double poids) {
    if (poidsMin != null && poids < poidsMin!) return false;
    if (poidsMax != null && poids > poidsMax!) return false;
    return true;
  }
}

class PosologieData {
  final String voie;
  final double? doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final List<TrancheData>? tranches;
  final String unite;
  final String preparation;
  final double? doseMax;

  PosologieData({
    required this.voie,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.tranches,
    required this.unite,
    required this.preparation,
    this.doseMax,
  });

  factory PosologieData.fromJson(Map<String, dynamic> json) {
    return PosologieData(
      voie: json['voie'] ?? '',
      doseKg: json['doseKg']?.toDouble(),
      doseKgMin: json['doseKgMin']?.toDouble(),
      doseKgMax: json['doseKgMax']?.toDouble(),
      tranches: (json['tranches'] as List?)
          ?.map((t) => TrancheData.fromJson(t))
          .toList(),
      unite: json['unite'] ?? '',
      preparation: json['preparation'] ?? '',
      doseMax: json['doseMax']?.toDouble(),
    );
  }

  String calculerDose(double poids) {
    if (tranches != null && tranches!.isNotEmpty) {
      final tranche = tranches!.firstWhere(
        (t) => t.appliqueAPoids(poids),
        orElse: () => tranches!.first,
      );
      
      if (tranche.doseKgMin != null && tranche.doseKgMax != null) {
        final doseMin = tranche.doseKgMin! * poids;
        final doseMax = tranche.doseKgMax! * poids;
        return _formatDoseAvecUnite(doseMin, doseMax, unite);
      } else {
        final dose = tranche.doseKg * poids;
        return _formatDoseAvecUnite(dose, null, unite);
      }
    }
    
    if (doseKgMin != null && doseKgMax != null) {
      final doseMin = doseKgMin! * poids;
      final doseMax = doseKgMax! * poids;
      
      // ignore: unnecessary_null_comparison
      if (doseMax != null) {
        final doseMinFinal = doseMin > doseMax ? doseMax : doseMin;
        final doseMaxFinal = doseMax > doseMax ? doseMax : doseMax;
        // ignore: unnecessary_brace_in_string_interps
        return '${_formatDoseAvecUnite(doseMinFinal, doseMaxFinal, unite)} (max ${doseMax} $unite)';
      }
      
      // ignore: dead_code
      return _formatDoseAvecUnite(doseMin, doseMax, unite);
    } else {
      final dose = doseKg! * poids;
      
      if (doseMax != null && dose > doseMax!) {
        return '${_formatDoseAvecUnite(doseMax!, null, unite)} (max atteint)';
      }
      
      return _formatDoseAvecUnite(dose, null, unite);
    }
  }

  String _formatDoseAvecUnite(double dose1, double? dose2, String uniteOriginale) {
    if (uniteOriginale == 'mg') {
      if (dose1 < 0.1) {
        if (dose2 != null) {
          return '${(dose1 * 1000).toStringAsFixed(0)} - ${(dose2 * 1000).toStringAsFixed(0)} µg';
        }
        return '${(dose1 * 1000).toStringAsFixed(0)} µg';
      }
    } else if (uniteOriginale == 'µg') {
      if (dose1 > 999) {
        if (dose2 != null) {
          return '${(dose1 / 1000).toStringAsFixed(1)} - ${(dose2 / 1000).toStringAsFixed(1)} mg';
        }
        return '${(dose1 / 1000).toStringAsFixed(1)} mg';
      }
    }
    
    if (dose2 != null) {
      return '${dose1.toStringAsFixed(1)} - ${dose2.toStringAsFixed(1)} $uniteOriginale';
    }
    return '${dose1.toStringAsFixed(1)} $uniteOriginale';
  }
}