# ped_app
Massio !! 

# Guide de contribution - Application Thérapeutique Pédiatrique

## 📋 Table des matières

1. [Introduction](#introduction)
2. [Architecture des données](#architecture-des-données)
3. [Ajouter un nouveau médicament](#ajouter-un-nouveau-médicament)
4. [Créer un nouveau protocole](#créer-un-nouveau-protocole)
5. [Synchronisation automatique](#synchronisation-automatique)
6. [Bonnes pratiques](#bonnes-pratiques)
7. [Validation et tests](#validation-et-tests)

---

## 📖 Introduction

Cette application permet aux professionnels de santé d'accéder rapidement aux posologies pédiatriques et aux protocoles d'urgence. Les données sont stockées dans des fichiers JSON et synchronisées automatiquement via GitHub.

### Flux de données

```
GitHub Repository (ped_app_data)
    ↓ (Synchronisation automatique)
Application mobile
    ↓ (Lecture locale)
Affichage des médicaments et protocoles
```

---

## 🗂️ Architecture des données

### Fichiers principaux

```
assets/
├── medicaments_pediatrie.json    # Base de données des médicaments
├── annuaire.json                 # Contacts internes/externes
└── protocoles/
    ├── etat_de_mal_epileptique.json
    └── arret_cardio_respiratoire.json
```

### Repository GitHub

```
Z4rsi0/ped_app_data
├── medicaments_pediatrie.json
├── annuaire.json
└── protocoles/
    ├── etat_de_mal_epileptique.json
    └── arret_cardio_respiratoire.json
```

---

## 💊 Ajouter un nouveau médicament

### Structure JSON d'un médicament

```json
{
  "nom": "Nom DCI du médicament",
  "nomCommercial": "NOM COMMERCIAL",
  "galenique": "Description de la forme galénique",
  "indications": [
    {
      "label": "Indication thérapeutique",
      "posologies": [
        {
          "voie": "IV",
          "doseKg": 10,
          "unite": "mg",
          "preparation": "Instructions de préparation"
        }
      ]
    }
  ],
  "contreIndications": "Liste des contre-indications",
  "surdosage": "Informations sur le surdosage",
  "aSavoir": "Informations importantes"
}
```

### Champs obligatoires

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `nom` | String | Dénomination Commune Internationale (DCI) | `"Paracétamol IV"` |
| `galenique` | String | Forme pharmaceutique | `"Solution perfusion 10 mg/mL"` |
| `indications` | Array | Liste des indications | `[{...}]` |

### Champs optionnels

| Champ | Type | Description |
|-------|------|-------------|
| `nomCommercial` | String | Nom de marque |
| `contreIndications` | String | Contre-indications et incompatibilités |
| `surdosage` | String | Gestion du surdosage |
| `aSavoir` | String | Informations complémentaires |

---

## 📊 Structure des posologies

### Posologie simple (dose fixe par kg)

```json
{
  "voie": "IV",
  "doseKg": 15,
  "unite": "mg",
  "preparation": "Prêt à l'emploi - IV lente 15 min"
}
```

**Résultat pour un enfant de 10 kg :** `150 mg`

### Posologie avec intervalle

```json
{
  "voie": "IV",
  "doseKgMin": 10,
  "doseKgMax": 20,
  "unite": "mg",
  "preparation": "Dilution NaCl 0,9%"
}
```

**Résultat pour un enfant de 10 kg :** `100 - 200 mg`

### Posologie avec dose maximale

```json
{
  "voie": "IV",
  "doseKg": 15,
  "doseMax": 1000,
  "unite": "mg",
  "preparation": "IV lente 15 min"
}
```

**Résultats :**
- Enfant de 10 kg : `150 mg`
- Enfant de 80 kg : `1000 mg (max atteint)`

### Posologie par tranches de poids/âge

```json
{
  "voie": "IV",
  "tranches": [
    {
      "poidsMax": 10,
      "doseKg": 7.5,
      "unite": "mg"
    },
    {
      "poidsMin": 10,
      "doseKg": 15,
      "unite": "mg"
    }
  ],
  "unite": "mg",
  "preparation": "IV lente"
}
```

**Résultats :**
- Enfant de 8 kg : `60 mg` (7.5 × 8)
- Enfant de 15 kg : `225 mg` (15 × 15)

### Posologie avec schéma complexe

```json
{
  "voie": "SC",
  "tranches": [
    {
      "poidsMax": 40,
      "doses": "S0: 80 mg, S2: 40 mg, S4: 20 mg puis 20 mg/15j"
    },
    {
      "poidsMin": 40,
      "doses": "S0: 160 mg, S2: 80 mg, S4: 40 mg puis 40 mg/15j"
    }
  ],
  "unite": "mg",
  "preparation": "Prêt à l'emploi"
}
```

**Utilisation :** Pour les schémas d'induction complexes (ex: Adalimumab)

---

## 🔢 Types de données acceptés

### Pour les doses

| Champ | Type | Obligatoire | Exemple | Description |
|-------|------|-------------|---------|-------------|
| `doseKg` | Number | Non* | `15` | Dose en unité/kg |
| `doseKgMin` | Number | Non* | `10` | Dose minimale en unité/kg |
| `doseKgMax` | Number | Non* | `20` | Dose maximale en unité/kg |
| `doseMax` | Number | Non | `1000` | Dose maximale absolue |
| `doses` | String | Non* | `"S0: 80 mg..."` | Schéma complexe |

*Au moins un de ces champs doit être présent

### Pour les tranches

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `ageMin` | Number | Âge minimum (années) | `6` |
| `ageMax` | Number | Âge maximum (années) | `15` |
| `poidsMin` | Number | Poids minimum (kg) | `10` |
| `poidsMax` | Number | Poids maximum (kg) | `40` |

### Unités acceptées

| Unité | Usage |
|-------|-------|
| `mg` | Milligrammes (standard) |
| `µg` | Microgrammes |
| `g` | Grammes |
| `UI` | Unités Internationales |
| `mL` | Millilitres |
| `UI/kg/h` | Perfusion continue (héparine) |
| `µg/kg/min` | Perfusion continue (catécholamines) |
| `mg/kg/h` | Perfusion continue |
| `ng/kg/min` | Perfusion continue (prostaglandines) |

---

## 📝 Exemple complet : Ajouter le Tramadol

```json
{
  "nom": "Tramadol",
  "nomCommercial": "TOPALGIC",
  "galenique": "Solution injectable 100 mg/2 mL",
  "indications": [
    {
      "label": "Douleur modérée à sévère",
      "posologies": [
        {
          "voie": "IV",
          "tranches": [
            {
              "ageMin": 3,
              "doseKgMin": 1,
              "doseKgMax": 2,
              "unite": "mg"
            }
          ],
          "unite": "mg",
          "preparation": "Dilution NaCl 0,9% ou G5% - IV lente 2-3 min"
        },
        {
          "voie": "IVSE",
          "doseKgMin": 4,
          "doseKgMax": 8,
          "unite": "mg/kg/jour",
          "preparation": "Perfusion continue sur 24h"
        }
      ]
    }
  ],
  "contreIndications": "Insuffisance respiratoire sévère, épilepsie non contrôlée, IMAO",
  "surdosage": "Dépression respiratoire. Antidote: naloxone 0,01 mg/kg",
  "aSavoir": "AMM à partir de 3 ans. Surveillance FR. Risque de convulsions à forte dose"
}
```

### Étapes pour ajouter ce médicament

1. **Ouvrir le fichier** `medicaments_pediatrie.json`
2. **Trouver la position alphabétique** (Tramadol se place après Thiopental)
3. **Copier le JSON ci-dessus**
4. **Ajouter une virgule** après le médicament précédent
5. **Coller le nouveau médicament**
6. **Valider le JSON** (voir section validation)
7. **Commit et push** vers GitHub

---

## 📋 Créer un nouveau protocole

### Structure JSON d'un protocole

```json
{
  "nom": "Titre du protocole",
  "description": "Description courte du protocole",
  "etapes": [
    {
      "titre": "Nom de l'étape",
      "temps": "T0",
      "elements": [
        {
          "type": "texte",
          "texte": "Instructions en texte libre"
        },
        {
          "type": "medicament",
          "medicament": {
            "nom": "Nom du médicament",
            "indication": "Indication spécifique",
            "voie": "IV"
          }
        }
      ],
      "attention": "⚠️ Alerte importante"
    }
  ]
}
```

### Types d'éléments dans une étape

#### 1. Élément texte

```json
{
  "type": "texte",
  "texte": "• Libération des voies aériennes\n• Oxygénothérapie\n• Position latérale de sécurité"
}
```

**Formatage du texte :**
- `\n` pour les sauts de ligne
- `•` pour les puces
- `**texte**` pour le gras (non supporté actuellement)

#### 2. Élément médicament

```json
{
  "type": "medicament",
  "medicament": {
    "nom": "Midazolam",
    "indication": "Convulsions",
    "voie": "IV"
  }
}
```

**Fonctionnement :**
- L'application recherche automatiquement le médicament dans `medicaments_pediatrie.json`
- Elle affiche la dose calculée pour le poids de l'enfant
- Elle affiche la préparation et les instructions

### Champs d'une étape

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `titre` | String | ✅ | Titre de l'étape |
| `temps` | String | ❌ | Timing (T0, T5, T10...) |
| `elements` | Array | ✅ | Liste des éléments |
| `attention` | String | ❌ | Alerte/warning important |

---

## 🚨 Exemple complet : Protocole Anaphylaxie

```json
{
  "nom": "Anaphylaxie",
  "description": "Prise en charge de la réaction anaphylactique sévère chez l'enfant",
  "etapes": [
    {
      "titre": "Reconnaissance",
      "temps": "T0",
      "elements": [
        {
          "type": "texte",
          "texte": "Critères diagnostiques:\n• Atteinte cutanée (urticaire, œdème)\n• Atteinte respiratoire (dyspnée, bronchospasme)\n• Atteinte cardiovasculaire (hypotension, tachycardie)\n• Atteinte digestive (vomissements, diarrhée)"
        }
      ],
      "attention": "Au moins 2 organes atteints = ANAPHYLAXIE"
    },
    {
      "titre": "Mesures immédiates",
      "temps": "< 1 min",
      "elements": [
        {
          "type": "texte",
          "texte": "• Arrêter l'exposition à l'allergène\n• Position allongée, jambes surélevées\n• Oxygène 100% au masque haute concentration\n• Voie veineuse périphérique\n• Scope, SpO2, PA"
        }
      ]
    },
    {
      "titre": "Adrénaline IM",
      "temps": "T0",
      "elements": [
        {
          "type": "medicament",
          "medicament": {
            "nom": "Adrénaline",
            "indication": "Anaphylaxie",
            "voie": "IM"
          }
        },
        {
          "type": "texte",
          "texte": "Site d'injection: face antéro-latérale de la cuisse\nRépéter toutes les 5-15 min si besoin"
        }
      ],
      "attention": "L'adrénaline IM est le traitement de première ligne"
    },
    {
      "titre": "Remplissage vasculaire",
      "temps": "T0-T5",
      "elements": [
        {
          "type": "texte",
          "texte": "NaCl 0,9% : 20 mL/kg en bolus rapide\nRépéter si nécessaire (jusqu'à 60 mL/kg)"
        }
      ]
    },
    {
      "titre": "Traitements adjuvants",
      "temps": "T5-T10",
      "elements": [
        {
          "type": "medicament",
          "medicament": {
            "nom": "Hydrocortisone",
            "indication": "Anti-inflammatoire",
            "voie": "IV"
          }
        },
        {
          "type": "texte",
          "texte": "\nAntihistaminique H1 (Polaramine):\n• < 3 ans: 2,5 mg IV\n• 3-6 ans: 5 mg IV\n• > 6 ans: 7,5 mg IV"
        }
      ]
    },
    {
      "titre": "Anaphylaxie réfractaire",
      "temps": "> T15",
      "elements": [
        {
          "type": "texte",
          "texte": "Si persistance des symptômes malgré 2 doses d'adrénaline IM:\n\n• Adrénaline IV: 0,1-1 µg/kg/min en IVSE\n• Débuter à 0,1 µg/kg/min\n• Augmenter par paliers de 0,1 µg/kg/min\n• Titrer selon PA et FC\n\n⚠️ Appel réanimation pédiatrique"
        }
      ],
      "attention": "Transfert en réanimation obligatoire"
    },
    {
      "titre": "Surveillance",
      "elements": [
        {
          "type": "texte",
          "texte": "• Scope continu pendant 6-8h minimum\n• Surveillance clinique: FR, PA, FC, SpO2, état cutané\n• Risque de réaction biphasique (1-20% des cas)\n• Hospitalisation obligatoire\n• Prescrire stylo d'adrénaline auto-injectable à la sortie\n• Consultation allergologie programmée"
        }
      ]
    }
  ]
}
```

### Créer le fichier protocole

1. **Créer un nouveau fichier** dans `assets/protocoles/`
   - Nom : `anaphylaxie.json` (en minuscules, sans espaces)

2. **Copier le JSON** ci-dessus

3. **Ajouter le protocole à la liste** dans `lib/protocoles.dart` :

```dart
Future<List<String>> loadProtocolesList() async {
  return [
    'etat_de_mal_epileptique',
    'arret_cardio_respiratoire',
    'anaphylaxie',  // ← Ajouter ici
  ];
}
```

4. **Mettre à jour le workflow GitHub** dans `.github/workflows/sync_data.yml` :

```yaml
- name: Prepare export
  run: |
    mkdir export
    cp -r assets/*.json export/ || true
    mkdir -p export/protocoles
    cp -r assets/protocoles/*.json export/protocoles/ || true
```

5. **Commit et push**

---

## 🔄 Synchronisation automatique

### Workflow GitHub Actions

Le fichier `.github/workflows/sync_data.yml` synchronise automatiquement les données :

```yaml
name: Sync JSON files to ped_app_data

on:
  push:
    branches: [ main ]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout main repo
        uses: actions/checkout@v4

      - name: Prepare export
        run: |
          mkdir export
          cp -r assets/*.json export/ || true
          mkdir -p export/protocoles
          cp -r assets/protocoles/*.json export/protocoles/ || true

      - name: Push to ped_app_data repo
        uses: peaceiris/actions-gh-pages@v3
        with:
          personal_token: ${{ secrets.SECOND_REPO_TOKEN }}
          external_repository: Z4rsi0/ped_app_data
          publish_dir: ./export
          publish_branch: main
```

### Comment ça marche ?

1. **Vous modifiez** un fichier JSON dans le repo principal
2. **Vous commit et push** vers GitHub
3. **GitHub Actions détecte** le push sur `main`
4. **Les fichiers JSON sont copiés** vers le repo `ped_app_data`
5. **L'application mobile** synchronise automatiquement au démarrage

### Vérifier la synchronisation

Au démarrage, l'application affiche :
- ✅ `4/4 synchronisés` → Tout est OK
- ⚠️ `2/4 synchronisés - 2 erreurs` → Problème de synchronisation

---

## ✅ Bonnes pratiques

### Organisation du code

```
📁 Repo principal (app Flutter)
│
├── assets/
│   ├── medicaments_pediatrie.json
│   ├── annuaire.json
│   └── protocoles/
│       ├── protocole1.json
│       └── protocole2.json
│
└── .github/workflows/sync_data.yml

📁 Repo données (ped_app_data)
│
├── medicaments_pediatrie.json
├── annuaire.json
└── protocoles/
    ├── protocole1.json
    └── protocole2.json
```

### Conventions de nommage

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Fichier médicament | snake_case | `medicaments_pediatrie.json` |
| Fichier protocole | snake_case | `etat_de_mal_epileptique.json` |
| Nom DCI | PascalCase ou Sentence case | `"Paracétamol IV"` |
| Nom commercial | MAJUSCULES | `"PERFALGAN"` |

### Formatage JSON

- **Indentation** : 2 espaces
- **Encodage** : UTF-8
- **Fin de ligne** : LF (Unix)
- **Pas de virgule finale** après le dernier élément

### Ordre des médicaments

Les médicaments doivent être classés **par ordre alphabétique** du nom DCI.

```json
[
  {"nom": "Acétazolamide", ...},
  {"nom": "Aciclovir", ...},
  {"nom": "Amikacine", ...}
]
```

---

## 🧪 Validation et tests

### Valider le JSON

#### En ligne

1. Copier le contenu du fichier JSON
2. Aller sur [JSONLint](https://jsonlint.com/)
3. Coller et cliquer sur "Validate JSON"

#### Avec VS Code

1. Installer l'extension "JSON" (Microsoft)
2. Ouvrir le fichier JSON
3. Les erreurs apparaissent en rouge

#### En ligne de commande

```bash
# Valider un fichier JSON
cat medicaments_pediatrie.json | jq .

# Si aucune erreur → le JSON est valide
```

### Tester dans l'application

1. **Modifier le fichier JSON** localement
2. **Remplacer** `assets/medicaments_pediatrie.json`
3. **Lancer l'application** en mode debug
4. **Vérifier** :
   - Le médicament apparaît dans la liste
   - Les doses se calculent correctement
   - La préparation s'affiche

### Checklist avant commit

- [ ] JSON valide (pas d'erreur de syntaxe)
- [ ] Tous les champs obligatoires présents
- [ ] Doses en nombres (pas de texte dans `doseKg`, `doseMax`)
- [ ] Unités cohérentes (`mg`, `µg`, `UI`...)
- [ ] Ordre alphabétique respecté
- [ ] Protocole ajouté à `loadProtocolesList()`
- [ ] Testé dans l'application

---

## 🐛 Erreurs courantes

### Erreur 1 : "toDouble() sur String"

**Cause :** Un champ numérique contient du texte

```json
// ❌ MAUVAIS
"doseMax": "5g acide clavulanique/jour"

// ✅ BON
"doseMax": 5000,
"aSavoir": "Dose max: 5g acide clavulanique/jour"
```

### Erreur 2 : "Out of memory"

**Cause :** Chemin de fichier incorrect dans le code

```dart
// ❌ MAUVAIS
await DataSyncService.readFile('assets/assets/protocoles/...')

// ✅ BON
await DataSyncService.readFile('assets/protocoles/...')
```

### Erreur 3 : "Médicament non trouvé"

**Cause :** Nom DCI incorrect dans le protocole

```json
// Dans le protocole
{
  "type": "medicament",
  "medicament": {
    "nom": "Midazolam",  // ← Doit correspondre EXACTEMENT
    "indication": "Convulsions"
  }
}

// Dans medicaments_pediatrie.json
{
  "nom": "Midazolam",  // ← au nom ici
  ...
}
```

### Erreur 4 : "2/4 synchronisés"

**Cause :** Fichiers non ajoutés au workflow GitHub

```yaml
# Vérifier que tous les fichiers sont dans sync_data.yml
cp -r assets/protocoles/*.json export/protocoles/ || true
```

### Erreur 5 : Virgule manquante/en trop

```json
// ❌ MAUVAIS (virgule en trop)
[
  {"nom": "Médicament1"},
  {"nom": "Médicament2"},  // ← Pas de virgule après le dernier
]

// ✅ BON
[
  {"nom": "Médicament1"},
  {"nom": "Médicament2"}
]
```

---

## 📞 Support

### Questions fréquentes

**Q: Comment calculer la dose en mg/m² ?**
R: L'application ne supporte pas encore le calcul par surface corporelle. Utilisez des doses par kg ou des schémas fixes.

**Q: Peut-on ajouter des images ?**
R: Non, l'application ne supporte actuellement que le texte.

**Q: Comment tester sans déployer ?**
R: Modifiez directement les fichiers dans `assets/` et lancez l'app en mode debug.

**Q: Les protocoles sont-ils validés médicalement ?**
R: Les contributeurs doivent s'assurer de la validité médicale. Ce README explique uniquement l'aspect technique.

### Ressources

- [Documentation Flutter](https://docs.flutter.dev/)
- [JSONLint - Validateur JSON](https://jsonlint.com/)
- [VS Code](https://code.visualstudio.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## 📄 Licence et responsabilité

⚠️ **Important :** Cette application est un outil d'aide à la décision. Les prescripteurs restent responsables de leurs prescriptions. Toujours vérifier les informations avec des sources officielles (Vidal, RCP, protocoles institutionnels).

---

**Version du README :** 1.0  
**Dernière mise à jour :** 2025-01-07  
**Mainteneur :** Z4rsi0