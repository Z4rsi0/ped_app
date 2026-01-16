# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [1.2.0] - 2026-01-16

### 🔥 Nouveau Module : Toxicologie Pédiatrique
Lancement officiel de l'onglet **Toxicologie**, un outil d'aide à la décision pour les urgences pédiatriques.

* **Base de données complète :** Intégration de ~30 agents toxiques majeurs (Paracétamol, Ibuprofène, Cardiotropes, Piles bouton, etc.) avec données cinétiques (pic, demi-vie).
* **Calculateur de Risque Intelligent :**
    * Évaluation instantanée du risque (Vert/Orange/Rouge) basée sur la dose ingérée et le poids de l'enfant.
    * Gestion sécurisée de la "Dose inconnue" (considérée comme toxique par défaut).
* **Gestion des Antidotes :**
    * Détection automatique de l'antidote disponible (ex: N-Acétylcystéine pour le Paracétamol).
    * Affichage filtré des posologies spécifiques aux protocoles d'intoxication (masquage des indications hors urgence).
* **Conduite à Tenir (CAT) :** Affichage clair des actions immédiates et des critères d'hospitalisation.

### ✨ Améliorations UX / UI
* **Navigation :** Ajout de l'onglet "Toxicologie" dans la barre de navigation principale.
* **Saisie sécurisée :** Réinitialisation automatique du formulaire et de la dose lors du changement d'agent toxique pour éviter les erreurs de calcul.
* **Recherche :** Moteur d'autocomplétion performant (recherche par nom commercial ou DCI).

### 🛠 Technique & Maintenance
* **Architecture :** Implémentation d'une "Clean Architecture" séparant la logique métier (`ToxicologyLogic`) de la couche de données (`StorageService`).
* **Tests Unitaires :** Ajout d'une suite de tests complète (`toxicology_logic_test.dart`) garantissant la fiabilité des calculs de toxicité (scénarios limites, poids nuls, doses massives).
* **Base de Données :**
    * Nouveau fichier `assets/data/toxiques.json`.
    * Nouvelle Box Hive `toxicsBox` et adaptateurs associés.
* **CI/CD & Scripts :**
    * Correction critique du script `tool/build_menu.dart` : détection automatique de la racine du projet et utilisation de `runInShell` pour une compatibilité Windows/Mac/Linux parfaite.
    * Mise à jour du script de déploiement Web pour inclure les données toxiques.

---
*Note : Cette application est une aide au calcul et ne remplace pas l'avis d'un Centre Anti-Poison (CAP).*