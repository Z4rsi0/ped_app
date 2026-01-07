# Massio Ped - Assistant d'Urgences Pédiatriques

**Massio Ped** est une application mobile cross-platform (Android/iOS) développée en **Flutter**, destinée aux internes et praticiens en pédiatrie. Elle fournit un accès rapide, hors-ligne et interactif aux protocoles d'urgence, avec calcul automatique des doses médicamenteuses selon le poids de l'enfant.

---

## 🚀 Fonctionnalités Principales

* **Mode 100% Hors-ligne (Offline-first) :** L'application fonctionne sans internet grâce à une base de données locale (Hive).
* **Protocoles Interactifs :** Affichage dynamique de protocoles médicaux (Texte, Tableaux, Alertes).
* **Calculateur de Doses Intégré :**
    * Sélection du poids global (via la barre d'application).
    * Calcul automatique des posologies (mg/kg) et des volumes (mL) dans les fiches médicaments.
* **Guide Thérapeutique :** Base de données complète des médicaments (DCI, Nom commercial, Indications).
* **Annuaire de Garde :** Liste des contacts utiles avec numérotation directe.
* **Recherche Intelligente :** Recherche normalisée (insensible aux accents/casse) sur les protocoles et médicaments.
* **Thèmes :** Support du Mode Clair et Mode Sombre.

---

## 🛠 Architecture Technique

Le projet suit une architecture propre et modulaire favorisant la maintenabilité.

### Structure des Dossiers (`/lib`)

* **`logic/`** : Contient la logique métier pure (ex: `DoseCalculator` pour les algos de calcul).
* **`models/`** : Modèles de données annotés pour Hive (`Protocol`, `Medicament`, `Annuaire`...).
* **`providers/`** : Gestion d'état via `Provider` (ex: `WeightProvider` pour l'état global du poids).
* **`screens/`** : Les pages de l'application (`ProtocolesScreen`, `Therapeutique`, `Annuaire`...).
* **`services/`** : La couche de données.
    * `StorageService` : Gestion bas niveau de la BDD Hive (CRUD).
    * `DataSyncService` : Chargement des JSONs depuis les assets et synchronisation vers Hive.
    * `MedicamentResolver` : Lien dynamique entre les noms de médicaments dans les protocoles et la base thérapeutique.
* **`themes/`** : Configuration du design system (`AppTheme`).
* **`utils/`** : Utilitaires (ex: `StringUtils` pour la normalisation de texte).
* **`widgets/`** : Composants réutilisables (`ProtocolBlockWidgets`, `GlobalWeightSelector`).

### Technologies Clés

* **Flutter** (SDK ≥ 3.35) & **Dart** (≥ 3.5).
* **Hive** : Base de données NoSQL légère et ultra-rapide pour la persistance locale.
* **Provider** : Injection de dépendances et gestion d'état.
* **Url Launcher** : Pour les appels téléphoniques depuis l'annuaire.

---

## 💾 Gestion des Données (Protocoles & Médicaments)

L'application est alimentée par des fichiers **JSON** situés dans le dossier `assets/`.
Au démarrage, le `DataSyncService` lit ces fichiers et met à jour la base locale Hive.

### 1. Ajouter un Protocole (`assets/protocoles/`)
Le format JSON est structuré en blocs (`ProtocolBlock`). Exemple de structure :

```json
{
  "titre": "Titre du Protocole",
  "categorie": "Urgence",
  "blocs": [
    {
      "type": "texte",
      "contenu": "Description clinique..."
    },
    {
      "type": "alerte",
      "niveau": "critique",
      "contenu": "Attention, urgence vitale."
    },
    {
      "type": "medicament",
      "nomMedicament": "Paracétamol",
      "indication": "Douleur",
      "commentaire": "Dose de charge..."
    }
  ]
}
