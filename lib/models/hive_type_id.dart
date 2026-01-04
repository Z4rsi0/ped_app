/// REGISTRE CENTRAL DES TYPE_ID HIVE
///
/// Ce fichier agit comme la "Source Unique de Vérité" pour la sérialisation binaire.
///
/// RÈGLES D'OR POUR LE DÉVELOPPEUR :
/// 1. Ne JAMAIS modifier un ID existant une fois l'app en production.
/// 2. Ne JAMAIS réutiliser un ID d'une classe supprimée (cela corromprait les backups locaux).
/// 3. Toujours ajouter les nouveaux IDs à la suite.

class HiveTypeId {
  // --- DOMAINE MÉDICAMENT (Plage 0 - 19) ---
  static const int medicament = 0;
  static const int indication = 1;
  static const int posologie = 2;
  static const int tranche = 3;

  // --- DOMAINE PROTOCOLE (Plage 20 - 29) ---
  static const int protocol = 20;

  // --- DOMAINE BLOCS DE PROTOCOLE (Plage 30 - 100) ---
  // Polymorphisme : Chaque sous-type de ProtocolBlock doit avoir un ID unique
  // pour que Hive sache quelle classe instancier lors de la lecture.
  
  static const int blockSection = 30;
  static const int blockTexte = 31;
  static const int blockTexteFormat = 32; // Helper class pour le style
  static const int blockTableau = 33;
  static const int blockImage = 34;
  static const int blockMedicament = 35;
  
  // Blocs avancés pour les formulaires / calculateurs
  static const int blockFormulaire = 36;
  static const int blockFormulaireChamp = 37;          // Helper
  static const int blockFormulaireOption = 38;         // Helper
  static const int blockFormulaireInterpretation = 39; // Helper
  
  static const int blockAlerte = 40;

  // Enums techniques (Ajoutés pour la compilation Hive)
  static const int alerteNiveau = 41;
  static const int champType = 42;
  static const int blockType = 43; // Utile si on stocke le type explicitement
  
  // Future extensions (ex: Toxicologie) : Réserver 44+ ici

  // --- DOMAINE ANNUAIRE (Plage 101 - 120) ---
  static const int annuaire = 101;
  static const int service = 102;
  static const int contact = 103;
  
  // --- DOMAINE UTILISATEUR / SETTINGS (Plage 200+) ---
  // (Réservé pour le Sprint 3 : Favoris, Historique...)
}