import '../models/medication_model.dart';

class DoseCalculator {
  /// Calcule la dose textuelle à afficher pour un poids donné
  static String calculate(Posologie posologie, double poids) {
    final uniteCalculee = _getUniteCalculee(posologie.unite);

    // 1. Schémas complexes globaux (Priorité absolue)
    if (posologie.doses != null && posologie.doses!.isNotEmpty) {
      return posologie.doses!;
    }

    // 2. Gestion par tranches (Priorité sur dose simple)
    if (posologie.tranches != null && posologie.tranches!.isNotEmpty) {
      Tranche tranche;
      try {
        tranche = posologie.tranches!.firstWhere(
          (t) => t.appliqueAPoids(poids),
        );
      } catch (e) {
        // Fallback sécurisé : si le poids est hors limites (ex: préma), on prend la première tranche
        // TODO: En production médicale, on pourrait retourner "Hors AMM/Protocole"
        tranche = posologie.tranches!.first;
      }

      if (tranche.doses != null && tranche.doses!.isNotEmpty) {
        return tranche.doses!;
      }

      final trancheUnite = tranche.unite != null 
          ? _getUniteCalculee(tranche.unite!) 
          : uniteCalculee;

      if (tranche.doseKgMin != null && tranche.doseKgMax != null) {
        final doseMin = tranche.doseKgMin! * poids;
        final doseMax = tranche.doseKgMax! * poids;
        return _formatDoseRange(doseMin, doseMax, trancheUnite);
      } else if (tranche.doseKg != null) {
        final dose = tranche.doseKg! * poids;
        return _formatSingleDose(dose, trancheUnite);
      }
    }

    // 3. Dose standard (Min/Max ou Simple)
    if (posologie.doseKgMin != null && posologie.doseKgMax != null) {
      final doseMinCalc = posologie.doseKgMin! * poids;
      final doseMaxCalc = posologie.doseKgMax! * poids;

      double? doseMaxAbsolue = _parseDouble(posologie.doseMax);
      
      if (doseMaxAbsolue != null) {
        // Plafonnement
        final doseMinFinal = doseMinCalc > doseMaxAbsolue ? doseMaxAbsolue : doseMinCalc;
        final doseMaxFinal = doseMaxCalc > doseMaxAbsolue ? doseMaxAbsolue : doseMaxCalc;
        
        final result = _formatDoseRange(doseMinFinal, doseMaxFinal, uniteCalculee);
        
        // Si on touche le plafond, on l'indique
        if (doseMaxCalc > doseMaxAbsolue) {
          return '$result (Plafond)';
        }
        return result;
      }

      return _formatDoseRange(doseMinCalc, doseMaxCalc, uniteCalculee);
    } 
    
    // 4. Dose simple par kg
    else if (posologie.doseKg != null) {
      final dose = posologie.doseKg! * poids;

      double? doseMaxAbsolue = _parseDouble(posologie.doseMax);
      if (doseMaxAbsolue != null && dose > doseMaxAbsolue) {
        return '${_formatSingleDose(doseMaxAbsolue, uniteCalculee)} (Max atteint)';
      }

      return _formatSingleDose(dose, uniteCalculee);
    }

    return "Dose non calculable";
  }

  /// Nettoie et normalise l'unité (retire le /kg)
  static String _getUniteCalculee(String unite) {
    // Normalisation : minuscules, trim
    String clean = unite.toLowerCase().trim();
    // Retirer /kg ou par kg ou / kg
    clean = clean.replaceAll(RegExp(r'\s*/\s*kg'), '');
    return clean;
  }

  /// Formate une dose unique avec conversion intelligente (mg <-> µg <-> g)
  static String _formatSingleDose(double dose, String unite) {
    final (value, unit) = _convertUnit(dose, unite);
    return '${_formatNumber(value)} $unit';
  }

  /// Formate une plage de dose
  static String _formatDoseRange(double min, double max, String unite) {
    final (minVal, minUnit) = _convertUnit(min, unite);
    final (maxVal, maxUnit) = _convertUnit(max, unite);

    // Si l'unité a changé pour les deux (ex: les deux en grammes), on affiche "1 - 2 g"
    if (minUnit == maxUnit) {
      return '${_formatNumber(minVal)} - ${_formatNumber(maxVal)} $minUnit';
    }
    // Sinon on affiche tout "800 mg - 1.2 g"
    return '${_formatNumber(minVal)} $minUnit - ${_formatNumber(maxVal)} $maxUnit';
  }

  /// Convertit les valeurs (ex: 1200 mg -> 1.2 g, 0.05 mg -> 50 µg)
  /// Retourne un tuple (valeur, nouvelleUnite)
  static (double, String) _convertUnit(double value, String unit) {
    String u = unit.trim();
    
    if (u == 'mg') {
      if (value < 0.1 && value > 0) {
        return (value * 1000, 'µg');
      }
      if (value >= 1000) {
        return (value / 1000, 'g');
      }
    } else if (u == 'µg' || u == 'ug') {
      if (value >= 1000) {
        return (value / 1000, 'mg');
      }
    } else if (u == 'g') {
      if (value < 1 && value > 0) {
        return (value * 1000, 'mg');
      }
    }
    
    return (value, u);
  }

  /// Formate les nombres proprement (pas de .0 inutile)
  static String _formatNumber(double n) {
    if (n == n.roundToDouble()) {
      return n.toStringAsFixed(0);
    }
    // Max 1 décimale si > 10, sinon max 2
    if (n > 10) return n.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return n.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').replaceAll(RegExp(r'[^\d\.]'), ''));
    }
    return null;
  }
}