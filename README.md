# Massio Ped - Documentation & Wiki

**Massio Ped** est une application d'aide à la décision médicale pour les urgences pédiatriques. 
Elle est conçue pour être **100% hors-ligne**, réactive et facile à mettre à jour.

Ce document sert de référence technique pour les développeurs et de guide de rédaction pour les contributeurs médicaux.

---

## 📑 Table des Matières

1. [Fonctionnalités](#-fonctionnalités)
2. [Architecture Technique](#-architecture-technique)
3. [Guide de Contribution (Contenu Médical)](#-guide-de-contribution-contenu-médical)
    - [Architecture des Données](#architecture-des-données)
    - [Rédiger un Protocole (JSON)](#rédiger-un-protocole-json)
    - [Ajouter un Médicament (JSON)](#ajouter-un-médicament-json)
4. [Synchronisation & Mise à jour](#-synchronisation--mise-à-jour)
5. [Installation & Développement](#-installation--développement)

---

## 🚀 Fonctionnalités

* **Mode Offline-First :** Base de données locale (Hive). Aucune connexion requise en urgence.
* **Calculateur de Dose Intelligent :** * Sélecteur de poids global (AppBar).
    * Calcul automatique des volumes (mL) et doses (mg) dans toutes les fiches.
    * Gestion des doses max, des âges et des concentrations.
* **Protocoles Dynamiques :** Affichage riche (Tableaux, Alertes, Sections dépliables, Images).
* **Moteur de Recherche :** Recherche floue (fuzzy logic) insensible aux accents et fautes de frappe.
* **Annuaire :** Numérotation directe (Click-to-call) interne et externe.
* **Lazy Loading :** Démarrage instantané (cache) et mise à jour silencieuse en arrière-plan.

---

## 🛠 Architecture Technique

Le projet est développé en **Flutter** (Dart).

### Structure des dossiers (`/lib`)

* **`models/`** : Les objets de données (Hive Adapters).
    * `protocol_model.dart` : Structure polymorphique des protocoles.
    * `medication_model.dart` : Logique pharmacologique.
* **`logic/`** : Moteur de calcul pur.
    * `dose_calculator.dart` : Contient toute la mathématique médicale (règle de 3, arrondis pédiatriques).
* **`services/`** : Gestion des données.
    * `storage_service.dart` : Interface avec la BDD locale (Hive).
    * `data_sync_service.dart` : Gestion du téléchargement intelligent (SHA check) depuis GitHub.
    * `medicament_resolver.dart` : Fait le lien entre un texte dans un protocole ("Paracétamol") et sa fiche technique complète.
* **`screens/`** : Les interfaces utilisateurs (`MainScreen`, `ProtocolesScreen`, etc.).
* **`widgets/`** : Composants réutilisables (`ProtocolBlockWidget`).

---

## ✍️ Guide de Contribution (Contenu Médical)

Toute l'intelligence de l'application réside dans les fichiers **JSON** situés dans le dossier `assets/`.
Il n'est pas nécessaire d'être développeur pour ajouter un protocole, il suffit de respecter la structure JSON.

### Architecture des Données

1.  **`assets/medicaments_pediatrie.json`** : La "Bible" pharmacologique. Contient tous les médicaments, concentrations et posologies.
2.  **`assets/protocoles/*.json`** : Un fichier par pathologie (ex: `asthme.json`, `epilepsie.json`).
3.  **`assets/annuaire.json`** : Liste des contacts.

---

### Rédiger un Protocole (JSON)

Un protocole est une suite de **Blocs**. Chaque bloc a un `type`.
Le fichier doit être placé dans `assets/protocoles/` et porter l'extension `.json`.

#### Structure de base

```json
{
  "titre": "Crise d'Asthme",
  "categorie": "Pneumologie",
  "description": "Prise en charge de la crise aiguë aux urgences.",
  "auteur": "Dr House",
  "version": "1.0",
  "blocs": [ ... ]
}
```

#### Les Types de Blocs Disponibles

**1. Bloc Texte** (Paragraphe simple)
```json
{
  "type": "texte",
  "contenu": "Le score de PRAM doit être évalué toutes les 20 minutes."
}
```

**2. Bloc Alerte** (Encadré coloré pour les urgences)
* Niveaux disponibles : `info` (Gris), `attention` (Orange), `danger` (Rouge), `critique` (Rouge vif + Bordure).
```json
{
  "type": "alerte",
  "niveau": "critique",
  "contenu": "Si silence auscultatoire : Risque d'arrêt imminent !"
}
```

**3. Bloc Médicament** (Lien intelligent)
* Ce bloc va chercher les infos dans la base médicaments et calculer la dose pour le poids sélectionné.
* `nomMedicament` doit correspondre exactement au `nom` dans `medicaments_pediatrie.json`.
```json
{
  "type": "medicament",
  "nomMedicament": "Salbutamol",
  "indication": "Nébulisation",
  "commentaire": "3 nébulisations à 20 min d'intervalle."
}
```

**4. Bloc Section** (Accordeon / Dépliable)
* Permet de grouper des étapes (ex: "T0 - Accueil", "T+20 min - Réévaluation").
* Peut contenir d'autres blocs à l'intérieur.
```json
{
  "type": "section",
  "titre": "Traitement de 1ère ligne",
  "temps": "T0",
  "initialementOuvert": true,
  "contenu": [
     { "type": "texte", "contenu": "Oxygène si SpO2 < 92%" },
     { "type": "medicament", "nomMedicament": "Salbutamol", "indication": "Nébulisation" }
  ]
}
```

**5. Bloc Tableau**
```json
{
  "type": "tableau",
  "titre": "Score de PRAM",
  "colonnes": ["Signe", "0 pt", "1 pt", "2 pts"],
  "lignes": [
    ["SpO2", ">94%", "92-94%", "<92%"],
    ["Tirage", "Absent", "Léger", "Intense"]
  ]
}
```

**6. Bloc Image**
* L'image peut être une URL (https) ou une image locale.
```json
{
  "type": "image",
  "source": "[https://example.com/schema_asthme.png](https://example.com/schema_asthme.png)",
  "legende": "Arbre décisionnel GFRUP"
}
```

---

### Ajouter un Médicament (JSON)

Modifiez le fichier `assets/medicaments_pediatrie.json`.

#### Exemple complet commenté

```json
{
  "nom": "Amoxicilline",              // Clé unique utilisée par les protocoles
  "nomCommercial": "Clamoxyl",        // Affichage secondaire
  "galenique": "Suspension buvable 500mg/5mL", // Pour info utilisateur
  "indications": [
    {
      "label": "Dose standard (Angine)",
      "posologies": [
        {
          "voie": "PO",
          "doseKg": 50,               // 50 mg/kg/j
          "doseMax": 3000,            // Max 3g/j absolue
          "unite": "mg",
          "concentration": 100,       // 500mg/5mL = 100mg/mL. Permet le calcul du volume.
          "frequence": "2 prises/j",
          "preparation": "À prendre au milieu des repas"
        }
      ]
    },
    {
      "label": "Otite Moyenne Aiguë",
      "posologies": [
        {
          "voie": "PO",
          "doseKg": 80,               // Dose plus forte
          "unite": "mg",
          "concentration": 100
        }
      ]
    }
  ],
  "contreIndications": "Allergie Pénicillines",
  "aSavoir": "Conservation frigo 14j."
}
```

#### Règles de calcul
Le `DoseCalculator` utilise la logique suivante :
1.  **Dose (mg) :** `Poids (kg) * doseKg` (bornée par `doseMax`).
2.  **Volume (mL) :** `Dose (mg) / concentration (mg/mL)`.
    * *Note :* Si le champ `concentration` est absent, seul le résultat en mg s'affiche.

---

## 🔄 Synchronisation & Mise à jour

L'application utilise un système de synchronisation intelligent ("Smart Sync") pour économiser la bande passante.

1.  **Au démarrage :** L'app affiche immédiatement les données en cache (Hive).
2.  **En arrière-plan :** Elle contacte GitHub pour vérifier les signatures (SHA) des fichiers.
3.  **Mise à jour différentielle :**
    * Si `protocole_A.json` a changé sur GitHub : Il est téléchargé et mis à jour.
    * Si `protocole_B.json` n'a pas changé : Il n'est **pas** téléchargé.
4.  **Rafraîchissement UI :** Dès que la mise à jour est finie, l'interface se met à jour automatiquement sous les yeux de l'utilisateur.

---

## 💻 Installation & Développement

### Pré-requis
* SDK Flutter >= 3.35
* Dart >= 3.5

### Commandes utiles

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Générer les adaptateurs Hive (Obligatoire si on modifie les Models !)
dart run build_runner build --delete-conflicting-outputs

# 3. Lancer l'app
flutter run
```

### Modifier le modèle de données
Si vous ajoutez un champ dans `ProtocolBlock` ou `Medicament` :
1.  Modifiez le fichier `.dart` dans `lib/models/`.
2.  Ajoutez l'annotation `@HiveField(n)`.
3.  Lancez la commande `build_runner` ci-dessus.

---

**Licence :** Usage interne / Médical.
**Responsabilité :** L'application est une aide mémoire. Le praticien reste seul responsable de la prescription.