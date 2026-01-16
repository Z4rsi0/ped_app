class HiveTypeId {
  // --- DOMAINE MÉDICAMENT (Plage 0 - 19) ---
  static const int medicament = 0;
  static const int indication = 1;
  static const int posologie = 2;
  static const int tranche = 3;

  // --- DOMAINE PROTOCOLE (Plage 20 - 29) ---
  static const int protocol = 20;

  // --- DOMAINE BLOCS DE PROTOCOLE (Plage 30 - 49) ---
  static const int blockSection = 30;
  static const int blockTexte = 31;
  static const int blockTexteFormat = 32;
  static const int blockTableau = 33;
  static const int blockImage = 34;
  static const int blockMedicament = 35;
  
  static const int blockFormulaire = 36;
  static const int blockFormulaireChamp = 37;
  static const int blockFormulaireOption = 38;
  static const int blockFormulaireInterpretation = 39;
  
  static const int blockAlerte = 40;
  static const int alerteNiveau = 41;
  static const int champType = 42;
  static const int blockType = 43;

  // --- DOMAINE TOXICOLOGIE (Plage 50 - 69) ---
  static const int toxicAgent = 50;

  // --- DOMAINE ANNUAIRE (Plage 101 - 120) ---
  static const int annuaire = 101;
  static const int service = 102;
  static const int contact = 103;
}