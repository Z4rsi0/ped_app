import '../models/toxic_agent.dart';

/// Enumérations pour le résultat (Vert/Orange/Rouge)
enum ToxicityStatus {
  safe,      // Vert : Dose < Seuil
  uncertain, // Orange : Seuil inconnu, besoin nomogramme, ou "à définir"
  toxic      // Rouge : Dose > Seuil ou Dose inconnue
}

/// Objet de résultat qui sera consommé par l'UI
class ToxicityResult {
  final ToxicityStatus status;
  final String message;
  final double calculatedDose;
  final String unit; // Ex: mg/kg
  final ToxicAgent agent;

  ToxicityResult({
    required this.status,
    required this.message,
    required this.calculatedDose,
    required this.unit,
    required this.agent,
  });
}

/// Moteur de règles pures (Business Logic)
class ToxicologyLogic {
  
  /// Calcule la toxicité en fonction de la dose ingérée et du poids.
  /// Cette fonction est pure : mêmes entrées = même sortie.
  static ToxicityResult evaluateRisk({
    required ToxicAgent agent,
    required double ingestedDose, // Dose totale (ex: 500 mg)
    required double patientWeight, // Poids en kg
    required bool isDoseUnknown,   // Checkbox "Je ne sais pas"
  }) {
    // Règle 1 : L'inconnu est toujours considéré comme le pire scénario
    if (isDoseUnknown) {
      return ToxicityResult(
        status: ToxicityStatus.toxic,
        message: "Dose inconnue : Risque potentiel maximal. Surveillance impérative.",
        calculatedDose: 0,
        unit: agent.unite,
        agent: agent,
      );
    }

    // Règle 2 : Calcul de la dose reçue
    // Note : On part du principe que l'input utilisateur est dans la même unité numérateur que l'agent.
    // (Ex: si agent est en mg/kg, l'input est en mg).
    double doseReceived = ingestedDose / patientWeight;

    // Règle 3 : Pas de seuil défini (ex: Paracétamol qui nécessite nomogramme temps/dose)
    if (agent.doseToxique == null) {
      return ToxicityResult(
        status: ToxicityStatus.uncertain,
        message: "Seuil fixe non applicable. Consulter la conduite à tenir détaillée.",
        calculatedDose: doseReceived,
        unit: agent.unite,
        agent: agent,
      );
    }

    // Règle 4 : Comparaison seuil
    if (doseReceived >= agent.doseToxique!) {
      return ToxicityResult(
        status: ToxicityStatus.toxic,
        message: "Dose toxique atteinte (Seuil : ${agent.doseToxique} ${agent.unite}).",
        calculatedDose: doseReceived,
        unit: agent.unite,
        agent: agent,
      );
    } else {
      return ToxicityResult(
        status: ToxicityStatus.safe,
        message: "Dose supposée infra-toxique (Seuil : ${agent.doseToxique} ${agent.unite}).",
        calculatedDose: doseReceived,
        unit: agent.unite,
        agent: agent,
      );
    }
  }
}