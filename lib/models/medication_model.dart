import '../logic/dose_calculator.dart'; // Import du calculateur

/// Modèle unifié de médicament pour PedApp et MedicationEditor
class Medicament {
  final String nom;
  final String? nomCommercial;
  final String galenique;
  final List<Indication> indications;
  final String? contreIndications;
  final String? surdosage;
  final String? aSavoir;

  Medicament({
    required this.nom,
    this.nomCommercial,
    required this.galenique,
    required this.indications,
    this.contreIndications,
    this.surdosage,
    this.aSavoir,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      nom: json['nom'] ?? '',
      nomCommercial: json['nomCommercial'],
      galenique: json['galenique'] ?? '',
      indications: (json['indications'] as List?)
              ?.map((i) => Indication.fromJson(i))
              .toList() ??
          [],
      contreIndications: json['contreIndications'],
      surdosage: json['surdosage'],
      aSavoir: json['aSavoir'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      if (nomCommercial != null) 'nomCommercial': nomCommercial,
      'galenique': galenique,
      'indications': indications.map((i) => i.toJson()).toList(),
      if (contreIndications != null) 'contreIndications': contreIndications,
      if (surdosage != null) 'surdosage': surdosage,
      if (aSavoir != null) 'aSavoir': aSavoir,
    };
  }
}

class Indication {
  final String label;
  final List<Posologie> posologies;

  Indication({required this.label, required this.posologies});

  factory Indication.fromJson(Map<String, dynamic> json) {
    return Indication(
      label: json['label'] ?? '',
      posologies: (json['posologies'] as List?)
              ?.map((p) => Posologie.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'posologies': posologies.map((p) => p.toJson()).toList(),
    };
  }
}

class Posologie {
  final String voie;
  final double? doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final List<Tranche>? tranches;
  final String unite;
  final String preparation;
  final dynamic doseMax;
  final String? doses;

  Posologie({
    required this.voie,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.tranches,
    required this.unite,
    required this.preparation,
    this.doseMax,
    this.doses,
  });

  factory Posologie.fromJson(Map<String, dynamic> json) {
    return Posologie(
      voie: json['voie'] ?? '',
      doseKg: _parseDouble(json['doseKg']),
      doseKgMin: _parseDouble(json['doseKgMin']),
      doseKgMax: _parseDouble(json['doseKgMax']),
      tranches: (json['tranches'] as List?)
          ?.map((t) => Tranche.fromJson(t))
          .toList(),
      unite: json['unite'] ?? '',
      preparation: json['preparation'] ?? '',
      doseMax: json['doseMax'],
      doses: json['doses'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voie': voie,
      if (doseKg != null) 'doseKg': doseKg,
      if (doseKgMin != null) 'doseKgMin': doseKgMin,
      if (doseKgMax != null) 'doseKgMax': doseKgMax,
      if (tranches != null) 'tranches': tranches!.map((t) => t.toJson()).toList(),
      'unite': unite,
      if (preparation.isNotEmpty) 'preparation': preparation,
      if (doseMax != null) 'doseMax': doseMax,
      if (doses != null) 'doses': doses,
    };
  }

  /// Délégation du calcul au DoseCalculator pour centraliser la logique
  String calculerDose(double poids) {
    return DoseCalculator.calculate(this, poids);
  }

  String getUniteReference() => unite;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}

class Tranche {
  final double? poidsMin;
  final double? poidsMax;
  final double? ageMin;
  final double? ageMax;
  final double? doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final String? doses;
  final String? unite;

  Tranche({
    this.poidsMin,
    this.poidsMax,
    this.ageMin,
    this.ageMax,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.doses,
    this.unite,
  });

  factory Tranche.fromJson(Map<String, dynamic> json) {
    return Tranche(
      poidsMin: Posologie._parseDouble(json['poidsMin']),
      poidsMax: Posologie._parseDouble(json['poidsMax']),
      ageMin: Posologie._parseDouble(json['ageMin']),
      ageMax: Posologie._parseDouble(json['ageMax']),
      doseKg: Posologie._parseDouble(json['doseKg']),
      doseKgMin: Posologie._parseDouble(json['doseKgMin']),
      doseKgMax: Posologie._parseDouble(json['doseKgMax']),
      doses: json['doses'],
      unite: json['unite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (poidsMin != null) 'poidsMin': poidsMin,
      if (poidsMax != null) 'poidsMax': poidsMax,
      if (ageMin != null) 'ageMin': ageMin,
      if (ageMax != null) 'ageMax': ageMax,
      if (doseKg != null) 'doseKg': doseKg,
      if (doseKgMin != null) 'doseKgMin': doseKgMin,
      if (doseKgMax != null) 'doseKgMax': doseKgMax,
      if (doses != null) 'doses': doses,
      if (unite != null) 'unite': unite,
    };
  }

  bool appliqueAPoids(double poids) {
    if (poidsMin != null && poids < poidsMin!) return false;
    if (poidsMax != null && poids > poidsMax!) return false;
    return true;
  }
}