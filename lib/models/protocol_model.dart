import 'dart:convert';

/// Modèle de protocole avec architecture flexible par blocs
/// Chaque bloc peut être réordonné et a un type spécifique
class Protocol {
  final String titre;
  final String description;
  final String? auteur;
  final String? version;
  final DateTime? dateModification;
  final List<ProtocolBlock> blocs;

  Protocol({
    required this.titre,
    required this.description,
    this.auteur,
    this.version,
    this.dateModification,
    required this.blocs,
  });

  factory Protocol.fromJson(Map<String, dynamic> json) {
    return Protocol(
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      auteur: json['auteur'],
      version: json['version'],
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'])
          : null,
      blocs: (json['blocs'] as List<dynamic>?)
              ?.map((b) => ProtocolBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'description': description,
      if (auteur != null && auteur!.isNotEmpty) 'auteur': auteur,
      if (version != null && version!.isNotEmpty) 'version': version,
      if (dateModification != null)
        'dateModification': dateModification!.toIso8601String(),
      'blocs': blocs.map((b) => b.toJson()).toList(),
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Génère un nom de fichier sécurisé à partir du titre
  String generateFileName() {
    String normalized = titre
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .toLowerCase();

    String sanitized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (sanitized.isEmpty) {
      return 'protocole_sans_nom.json';
    }

    return '$sanitized.json';
  }
}

/// Types de blocs disponibles
enum BlockType {
  section,      // Section collapsible avec titre
  texte,        // Texte avec formatage (gras, italique, souligné)
  tableau,      // Tableau de données
  image,        // Image (base64 ou URL)
  medicament,   // Référence médicament avec calcul de dose
  formulaire,   // Formulaire interactif avec calculs (scores cliniques)
  alerte,       // Bloc d'alerte/attention
}

/// Bloc de protocole - classe de base
abstract class ProtocolBlock {
  final BlockType type;
  final int ordre;
  final String? id;

  ProtocolBlock({
    required this.type,
    required this.ordre,
    this.id,
  });

  Map<String, dynamic> toJson();

  factory ProtocolBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'texte';
    final type = BlockType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => BlockType.texte,
    );

    switch (type) {
      case BlockType.section:
        return SectionBlock.fromJson(json);
      case BlockType.texte:
        return TexteBlock.fromJson(json);
      case BlockType.tableau:
        return TableauBlock.fromJson(json);
      case BlockType.image:
        return ImageBlock.fromJson(json);
      case BlockType.medicament:
        return MedicamentBlock.fromJson(json);
      case BlockType.formulaire:
        return FormulaireBlock.fromJson(json);
      case BlockType.alerte:
        return AlerteBlock.fromJson(json);
    }
  }
}

/// Bloc Section - Tuile collapsible avec sous-blocs
class SectionBlock extends ProtocolBlock {
  final String titre;
  final String? temps;
  final bool initialementOuvert;
  final List<ProtocolBlock> contenu;

  SectionBlock({
    required int ordre,
    String? id,
    required this.titre,
    this.temps,
    this.initialementOuvert = false,
    required this.contenu,
  }) : super(type: BlockType.section, ordre: ordre, id: id);

  factory SectionBlock.fromJson(Map<String, dynamic> json) {
    return SectionBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      titre: json['titre'] ?? '',
      temps: json['temps'],
      initialementOuvert: json['initialementOuvert'] ?? false,
      contenu: (json['contenu'] as List<dynamic>?)
              ?.map((b) => ProtocolBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'titre': titre,
      if (temps != null && temps!.isNotEmpty) 'temps': temps,
      if (initialementOuvert) 'initialementOuvert': initialementOuvert,
      'contenu': contenu.map((b) => b.toJson()).toList(),
    };
  }
}

/// Bloc Texte - Texte avec formatage
class TexteBlock extends ProtocolBlock {
  final String contenu;
  final TexteFormat? format;

  TexteBlock({
    required int ordre,
    String? id,
    required this.contenu,
    this.format,
  }) : super(type: BlockType.texte, ordre: ordre, id: id);

  factory TexteBlock.fromJson(Map<String, dynamic> json) {
    return TexteBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      contenu: json['contenu'] ?? '',
      format: json['format'] != null
          ? TexteFormat.fromJson(json['format'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'contenu': contenu,
      if (format != null) 'format': format!.toJson(),
    };
  }
}

/// Format de texte
class TexteFormat {
  final bool gras;
  final bool italique;
  final bool souligne;
  final String? couleur;
  final double? taillePolicePx;

  TexteFormat({
    this.gras = false,
    this.italique = false,
    this.souligne = false,
    this.couleur,
    this.taillePolicePx,
  });

  factory TexteFormat.fromJson(Map<String, dynamic> json) {
    return TexteFormat(
      gras: json['gras'] ?? false,
      italique: json['italique'] ?? false,
      souligne: json['souligne'] ?? false,
      couleur: json['couleur'],
      taillePolicePx: (json['taillePolicePx'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (gras) map['gras'] = gras;
    if (italique) map['italique'] = italique;
    if (souligne) map['souligne'] = souligne;
    if (couleur != null) map['couleur'] = couleur;
    if (taillePolicePx != null) map['taillePolicePx'] = taillePolicePx;
    return map;
  }
}

/// Bloc Tableau - Tableau de données
class TableauBlock extends ProtocolBlock {
  final String? titre;
  final List<String> colonnes;
  final List<List<String>> lignes;
  final bool avecEntete;

  TableauBlock({
    required int ordre,
    String? id,
    this.titre,
    required this.colonnes,
    required this.lignes,
    this.avecEntete = true,
  }) : super(type: BlockType.tableau, ordre: ordre, id: id);

  factory TableauBlock.fromJson(Map<String, dynamic> json) {
    return TableauBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      titre: json['titre'],
      colonnes: (json['colonnes'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      lignes: (json['lignes'] as List<dynamic>?)
              ?.map((row) =>
                  (row as List<dynamic>).map((c) => c.toString()).toList())
              .toList() ??
          [],
      avecEntete: json['avecEntete'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      if (titre != null && titre!.isNotEmpty) 'titre': titre,
      'colonnes': colonnes,
      'lignes': lignes,
      if (!avecEntete) 'avecEntete': avecEntete,
    };
  }
}

/// Bloc Image - Image embarquée ou URL
class ImageBlock extends ProtocolBlock {
  final String source; // URL ou base64
  final bool estBase64;
  final String? legende;
  final double? largeurPourcent;

  ImageBlock({
    required int ordre,
    String? id,
    required this.source,
    this.estBase64 = false,
    this.legende,
    this.largeurPourcent,
  }) : super(type: BlockType.image, ordre: ordre, id: id);

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    return ImageBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      source: json['source'] ?? '',
      estBase64: json['estBase64'] ?? false,
      legende: json['legende'],
      largeurPourcent: (json['largeurPourcent'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'source': source,
      if (estBase64) 'estBase64': estBase64,
      if (legende != null && legende!.isNotEmpty) 'legende': legende,
      if (largeurPourcent != null) 'largeurPourcent': largeurPourcent,
    };
  }
}

/// Bloc Médicament - Référence vers un médicament avec calcul de dose
class MedicamentBlock extends ProtocolBlock {
  final String nomMedicament;
  final String indication;
  final String? voie;
  final String? commentaire;

  MedicamentBlock({
    required int ordre,
    String? id,
    required this.nomMedicament,
    required this.indication,
    this.voie,
    this.commentaire,
  }) : super(type: BlockType.medicament, ordre: ordre, id: id);

  factory MedicamentBlock.fromJson(Map<String, dynamic> json) {
    return MedicamentBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      nomMedicament: json['nomMedicament'] ?? json['nom'] ?? '',
      indication: json['indication'] ?? '',
      voie: json['voie'],
      commentaire: json['commentaire'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'nomMedicament': nomMedicament,
      'indication': indication,
      if (voie != null && voie!.isNotEmpty) 'voie': voie,
      if (commentaire != null && commentaire!.isNotEmpty)
        'commentaire': commentaire,
    };
  }
}

/// Bloc Formulaire - Formulaire interactif avec calculs (scores cliniques)
class FormulaireBlock extends ProtocolBlock {
  final String titre;
  final String? description;
  final List<FormulaireChamp> champs;
  final String? formuleCalcul;
  final List<FormulaireInterpretation>? interpretations;

  FormulaireBlock({
    required int ordre,
    String? id,
    required this.titre,
    this.description,
    required this.champs,
    this.formuleCalcul,
    this.interpretations,
  }) : super(type: BlockType.formulaire, ordre: ordre, id: id);

  factory FormulaireBlock.fromJson(Map<String, dynamic> json) {
    return FormulaireBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      titre: json['titre'] ?? '',
      description: json['description'],
      champs: (json['champs'] as List<dynamic>?)
              ?.map((c) =>
                  FormulaireChamp.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      formuleCalcul: json['formuleCalcul'],
      interpretations: (json['interpretations'] as List<dynamic>?)
          ?.map((i) =>
              FormulaireInterpretation.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'titre': titre,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'champs': champs.map((c) => c.toJson()).toList(),
      if (formuleCalcul != null && formuleCalcul!.isNotEmpty)
        'formuleCalcul': formuleCalcul,
      if (interpretations != null && interpretations!.isNotEmpty)
        'interpretations': interpretations!.map((i) => i.toJson()).toList(),
    };
  }
}

/// Type de champ de formulaire
enum ChampType {
  nombre,
  selection,
  checkbox,
  radio,
}

/// Champ de formulaire
class FormulaireChamp {
  final String id;
  final String label;
  final ChampType type;
  final List<FormulaireOption>? options;
  final num? min;
  final num? max;
  final num? defaut;
  final num? points; // Points attribués si checkbox cochée

  FormulaireChamp({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.defaut,
    this.points,
  });

  factory FormulaireChamp.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'nombre';
    final type = ChampType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => ChampType.nombre,
    );

    return FormulaireChamp(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: type,
      options: (json['options'] as List<dynamic>?)
          ?.map((o) => FormulaireOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      min: json['min'] as num?,
      max: json['max'] as num?,
      defaut: json['defaut'] as num?,
      points: json['points'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      if (options != null && options!.isNotEmpty)
        'options': options!.map((o) => o.toJson()).toList(),
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (defaut != null) 'defaut': defaut,
      if (points != null) 'points': points,
    };
  }
}

/// Option de sélection
class FormulaireOption {
  final String label;
  final num valeur;

  FormulaireOption({
    required this.label,
    required this.valeur,
  });

  factory FormulaireOption.fromJson(Map<String, dynamic> json) {
    return FormulaireOption(
      label: json['label'] ?? '',
      valeur: json['valeur'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'valeur': valeur,
    };
  }
}

/// Interprétation du score
class FormulaireInterpretation {
  final num min;
  final num max;
  final String texte;
  final String? couleur;
  final String? niveau; // ex: "faible", "modere", "eleve", "critique"

  FormulaireInterpretation({
    required this.min,
    required this.max,
    required this.texte,
    this.couleur,
    this.niveau,
  });

  factory FormulaireInterpretation.fromJson(Map<String, dynamic> json) {
    return FormulaireInterpretation(
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
      texte: json['texte'] ?? '',
      couleur: json['couleur'],
      niveau: json['niveau'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'texte': texte,
      if (couleur != null) 'couleur': couleur,
      if (niveau != null) 'niveau': niveau,
    };
  }
}

/// Bloc Alerte - Bloc d'attention/warning
class AlerteBlock extends ProtocolBlock {
  final String contenu;
  final AlerteNiveau niveau;

  AlerteBlock({
    required int ordre,
    String? id,
    required this.contenu,
    this.niveau = AlerteNiveau.attention,
  }) : super(type: BlockType.alerte, ordre: ordre, id: id);

  factory AlerteBlock.fromJson(Map<String, dynamic> json) {
    final niveauStr = json['niveau'] as String? ?? 'attention';
    final niveau = AlerteNiveau.values.firstWhere(
      (n) => n.name == niveauStr,
      orElse: () => AlerteNiveau.attention,
    );

    return AlerteBlock(
      ordre: json['ordre'] ?? 0,
      id: json['id'],
      contenu: json['contenu'] ?? '',
      niveau: niveau,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'ordre': ordre,
      if (id != null) 'id': id,
      'contenu': contenu,
      'niveau': niveau.name,
    };
  }
}

/// Niveaux d'alerte
enum AlerteNiveau {
  info,
  attention,
  danger,
  critique,
}