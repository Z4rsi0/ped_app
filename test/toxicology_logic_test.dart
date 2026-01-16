import 'package:flutter_test/flutter_test.dart';
import 'package:ped_app/logic/toxicology_logic.dart'; // Vérifie que le chemin correspond à ton projet
import 'package:ped_app/models/toxic_agent.dart';

void main() {
  group('ToxicologyLogic Tests', () {
    
    // Agent fictif pour les tests : Seuil à 100 mg/kg
    final testAgent = ToxicAgent(
      id: 'test_agent',
      nom: 'Testium',
      motsCles: [],
      doseToxique: 100.0, // Seuil à 100
      unite: 'mg/kg',
      picCinetique: '1h',
      demiVie: '2h',
      conduiteATenir: 'CAT',
      graviteExtreme: false,
      antidoteId: null,
    );

    // Agent sans seuil défini (ex: Paracétamol qui dépend d'un nomogramme)
    final complexAgent = ToxicAgent(
      id: 'complex_agent',
      nom: 'Complexium',
      motsCles: [],
      doseToxique: null, // Pas de seuil simple
      unite: 'mg/kg',
      picCinetique: null,
      demiVie: null,
      conduiteATenir: 'CAT',
      graviteExtreme: true,
      antidoteId: null,
    );

    test('Dose INFÉRIEURE au seuil doit être SAFE (Vert)', () {
      // 10kg, dose ingérée 500mg => 50 mg/kg (< 100)
      final result = ToxicologyLogic.evaluateRisk(
        agent: testAgent,
        ingestedDose: 500,
        patientWeight: 10,
        isDoseUnknown: false,
      );

      expect(result.status, ToxicityStatus.safe);
      expect(result.calculatedDose, 50.0);
    });

    test('Dose SUPÉRIEURE au seuil doit être TOXIC (Rouge)', () {
      // 10kg, dose ingérée 1500mg => 150 mg/kg (> 100)
      final result = ToxicologyLogic.evaluateRisk(
        agent: testAgent,
        ingestedDose: 1500,
        patientWeight: 10,
        isDoseUnknown: false,
      );

      expect(result.status, ToxicityStatus.toxic);
      expect(result.message, contains('Dose toxique atteinte'));
    });

    test('Dose ÉGALE au seuil doit être TOXIC (Rouge)', () {
      // 10kg, dose ingérée 1000mg => 100 mg/kg (== 100)
      final result = ToxicologyLogic.evaluateRisk(
        agent: testAgent,
        ingestedDose: 1000,
        patientWeight: 10,
        isDoseUnknown: false,
      );

      expect(result.status, ToxicityStatus.toxic);
    });

    test('Dose INCONNUE doit être TOXIC (Rouge) par précaution', () {
      final result = ToxicologyLogic.evaluateRisk(
        agent: testAgent,
        ingestedDose: 0, // Peu importe la dose
        patientWeight: 10,
        isDoseUnknown: true, // Case cochée
      );

      expect(result.status, ToxicityStatus.toxic);
      expect(result.message, contains('Dose inconnue'));
    });

    test('Agent sans seuil défini doit être UNCERTAIN (Orange)', () {
      final result = ToxicologyLogic.evaluateRisk(
        agent: complexAgent,
        ingestedDose: 500,
        patientWeight: 10,
        isDoseUnknown: false,
      );

      expect(result.status, ToxicityStatus.uncertain);
    });

    test('Poids nul ou invalide ne doit pas crasher (division par zéro)', () {
      // Si le poids est 0, la division donnerait Infinity
      final result = ToxicologyLogic.evaluateRisk(
        agent: testAgent,
        ingestedDose: 500,
        patientWeight: 0, 
        isDoseUnknown: false,
      );

      // Le comportement actuel mathématique donnera Infinity, 
      // qui est > 100, donc TOXIC. C'est le comportement "safe" voulu.
      expect(result.status, ToxicityStatus.toxic);
    });
  });
}