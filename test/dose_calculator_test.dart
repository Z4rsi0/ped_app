import 'package:flutter_test/flutter_test.dart';
import 'package:ped_app/logic/dose_calculator.dart'; // Vérifie le chemin d'import
import 'package:ped_app/models/medication_model.dart'; // Pour Posologie/Tranche

void main() {
  group('DoseCalculator - Tests de Sécurité', () {
    
    // CAS 1 : Dose simple par kg (ex: 15 mg/kg)
    test('Calcul simple dose/kg doit être exact', () {
      final posologie = Posologie(
        voie: 'Orale',
        unite: 'mg',
        preparation: '',
        doseKg: 15.0, // 15 mg/kg
      );

      // Pour un enfant de 10kg -> 150 mg
      expect(DoseCalculator.calculate(posologie, 10.0), '150 mg');
      
      // Pour un enfant de 4kg -> 60 mg
      expect(DoseCalculator.calculate(posologie, 4.0), '60 mg');
    });

    // CAS 2 : Gestion des arrondis et conversion d'unités
    test('Doit convertir mg en g si > 1000', () {
      final posologie = Posologie(
        voie: 'IV',
        unite: 'mg',
        preparation: '',
        doseKg: 20.0,
      );

      // 60kg * 20mg = 1200mg -> Doit afficher 1.2 g
      expect(DoseCalculator.calculate(posologie, 60.0), '1.2 g');
    });

    test('Doit convertir mg en µg si < 0.1 mg', () {
      final posologie = Posologie(
        voie: 'IV',
        unite: 'mg',
        preparation: '',
        doseKg: 0.005, // 0.005 mg/kg
      );

      // 10kg * 0.005 = 0.05 mg -> 50 µg
      expect(DoseCalculator.calculate(posologie, 10.0), '50 µg');
    });

    // CAS 3 : Plafonnement (Dose Max) - CRITIQUE
    test('Doit respecter la dose maximale absolue', () {
      final posologie = Posologie(
        voie: 'Orale',
        unite: 'mg',
        preparation: '',
        doseKg: 15.0,
        doseMax: 1000.0, // Max 1g (1000mg)
      );

      // Enfant de 100kg (théorique) : 100 * 15 = 1500mg
      // MAIS le max est 1000mg.
      // Le test doit vérifier qu'on bloque à 1g et qu'on affiche l'alerte.
      final resultat = DoseCalculator.calculate(posologie, 100.0);
      
      expect(resultat.contains('1 g'), true); // Doit afficher 1g
      expect(resultat.contains('Max atteint') || resultat.contains('Plafond'), true);
    });

    // CAS 4 : Gestion des Tranches (Complexe)
    test('Doit appliquer la bonne tranche de poids', () {
      final posologie = Posologie(
        voie: 'Orale',
        unite: 'mg',
        preparation: '',
        tranches: [
          Tranche(poidsMin: 0, poidsMax: 10, doseKg: 20), // 0-10kg : 20mg/kg
          Tranche(poidsMin: 10, poidsMax: 100, doseKg: 10), // >10kg : 10mg/kg
        ]
      );

      // Enfant 5kg (Tranche 1) -> 5 * 20 = 100mg
      expect(DoseCalculator.calculate(posologie, 5.0), '100 mg');

      // Enfant 20kg (Tranche 2) -> 20 * 10 = 200mg
      expect(DoseCalculator.calculate(posologie, 20.0), '200 mg');
    });

    // CAS 5 : Plages de doses (Min - Max)
    test('Doit afficher une fourchette (Min - Max)', () {
      final posologie = Posologie(
        voie: 'Orale',
        unite: 'mg',
        preparation: '',
        doseKgMin: 10.0,
        doseKgMax: 20.0,
      );

      // Enfant 10kg -> 100 - 200 mg
      expect(DoseCalculator.calculate(posologie, 10.0), '100 - 200 mg');
    });
  });
}
