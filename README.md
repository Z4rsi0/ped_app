# Massio Ped - Assistant d'Urgences Pédiatriques

**Massio Ped** est une application mobile cross-platform (Android/iOS) développée en **Flutter**, destinée aux internes et praticiens en pédiatrie. Elle fournit un accès rapide, **100% hors-ligne** et interactif aux protocoles d'urgence, avec un calculateur automatique de doses médicamenteuses intégré.

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
* **`providers/`** : Gestion d'état via Provider (ex: `WeightProvider` pour l'état global du poids).
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

L'application est alimentée par des fichiers JSON situés dans le dossier `assets/`.
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
```

### 2. Ajouter un Médicament (`assets/data/medicaments_pediatrie.json`)
C'est la base centrale. Les protocoles font référence au `nom` défini ici pour calculer les doses.

```json
{
  "nom": "Paracétamol",
  "galenique": "Solution buvable",
  "indications": [
    {
      "label": "Douleur / Fièvre",
      "posologies": [
        {
          "doseKg": 15,
          "doseMax": 1000,
          "voie": "PO"
        }
      ]
    }
  ]
}
```

---

## 🚀 Installation et Lancement

### Pré-requis
* Flutter SDK installé et configuré.
* Android Studio ou VS Code.

### Commandes usuelles

**Récupérer les dépendances :**
```bash
flutter pub get
```

**Générer les Adapters Hive (si modification des Models) :**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Lancer en mode Debug :**
```bash
flutter run
```

**Compiler pour la Production (APK) :**
```bash
flutter build apk --release
```

---

## 📱 Permissions Android

Le fichier `AndroidManifest.xml` est configuré pour respecter les règles strictes du Google Play Store.

* `<uses-permission android:name="android.permission.INTERNET"/>` : Pour d'éventuelles mises à jour futures.
* `<queries>` (Action `DIAL`) : Pour permettre l'ouverture du composeur téléphonique depuis l'annuaire.

---

## 🤝 Contribution

Si vous souhaitez modifier la logique de calcul de dose, référez-vous au fichier `lib/logic/dose_calculator.dart`. Assurez-vous de bien gérer les arrondis et les cas limites (poids hors tranches).

**Auteurs :**
* Développement : MASSIO
* Contenu Médical : [Noms des médecins référents]
