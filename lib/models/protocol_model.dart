import 'dart:convert';
import 'package:hive/hive.dart';
import 'hive_type_id.dart';

part 'protocol_model.g.dart';

/// Modèle de protocole avec architecture flexible par blocs
@HiveType(typeId: HiveTypeId.protocol)
class Protocol {
  @HiveField(0)
  final String titre;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final String? auteur;
  
  @HiveField(3)
  final String? version;
  
  @HiveField(4)
  final DateTime? dateModification;
  
  @HiveField(5)
  final List<ProtocolBlock> blocs;

  @HiveField(6)
  final String? categorie;

  Protocol({
    required this.titre,
    required this.description,
    this.auteur,
    this.version,
    this.dateModification,
    required this.blocs,
    this.categorie,
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
      categorie: json['categorie']
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
      if (categorie != null && categorie!.isNotEmpty) 'categorie': categorie,
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

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
@HiveType(typeId: HiveTypeId.blockType)
enum BlockType {
  @HiveField(0) section,
  @HiveField(1) texte,
  @HiveField(2) tableau,
  @HiveField(3) image,
  @HiveField(4) medicament,
  @HiveField(5) formulaire,
  @HiveField(6) alerte,
}

/// Bloc de protocole - classe de base
/// Note: On n'annote pas directement l'abstract class avec un TypeId 
/// car ce sont les instances concrètes (Enfants) qui sont stockées.
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
@HiveType(typeId: HiveTypeId.blockSection)
class SectionBlock extends ProtocolBlock {
  @HiveField(0)
  final String titre;
  
  @HiveField(1)
  final String? temps;
  
  @HiveField(2)
  final bool initialementOuvert;
  
  @HiveField(3)
  final List<ProtocolBlock> contenu;

  @HiveField(4)
  @override
  final int ordre;

  @HiveField(5)
  @override
  final String? id;

  SectionBlock({
    required this.ordre,
    this.id,
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
@HiveType(typeId: HiveTypeId.blockTexte)
class TexteBlock extends ProtocolBlock {
  @HiveField(0)
  final String contenu;
  
  @HiveField(1)
  final TexteFormat? format;

  @HiveField(2)
  @override
  final int ordre;

  @HiveField(3)
  @override
  final String? id;

  TexteBlock({
    required this.ordre,
    this.id,
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
@HiveType(typeId: HiveTypeId.blockTexteFormat)
class TexteFormat {
  @HiveField(0) final bool gras;
  @HiveField(1) final bool italique;
  @HiveField(2) final bool souligne;
  @HiveField(3) final String? couleur;
  @HiveField(4) final double? taillePolicePx;

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
@HiveType(typeId: HiveTypeId.blockTableau)
class TableauBlock extends ProtocolBlock {
  @HiveField(0)
  final String? titre;
  
  @HiveField(1)
  final List<String> colonnes;
  
  @HiveField(2)
  final List<List<String>> lignes;
  
  @HiveField(3)
  final bool avecEntete;

  @HiveField(4)
  @override
  final int ordre;

  @HiveField(5)
  @override
  final String? id;

  TableauBlock({
    required this.ordre,
    this.id,
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
@HiveType(typeId: HiveTypeId.blockImage)
class ImageBlock extends ProtocolBlock {
  @HiveField(0)
  final String source; // URL ou base64
  
  @HiveField(1)
  final bool estBase64;
  
  @HiveField(2)
  final String? legende;
  
  @HiveField(3)
  final double? largeurPourcent;

  @HiveField(4)
  @override
  final int ordre;

  @HiveField(5)
  @override
  final String? id;

  ImageBlock({
    required this.ordre,
    this.id,
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
@HiveType(typeId: HiveTypeId.blockMedicament)
class MedicamentBlock extends ProtocolBlock {
  @HiveField(0)
  final String nomMedicament;
  
  @HiveField(1)
  final String indication;
  
  @HiveField(2)
  final String? voie;
  
  @HiveField(3)
  final String? commentaire;

  @HiveField(4)
  @override
  final int ordre;

  @HiveField(5)
  @override
  final String? id;

  MedicamentBlock({
    required this.ordre,
    this.id,
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

/// Bloc Formulaire - Formulaire interactif avec calculs
@HiveType(typeId: HiveTypeId.blockFormulaire)
class FormulaireBlock extends ProtocolBlock {
  @HiveField(0)
  final String titre;
  
  @HiveField(1)
  final String? description;
  
  @HiveField(2)
  final List<FormulaireChamp> champs;
  
  @HiveField(3)
  final String? formuleCalcul;
  
  @HiveField(4)
  final List<FormulaireInterpretation>? interpretations;

  @HiveField(5)
  @override
  final int ordre;

  @HiveField(6)
  @override
  final String? id;

  FormulaireBlock({
    required this.ordre,
    this.id,
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

@HiveType(typeId: HiveTypeId.champType)
enum ChampType {
  @HiveField(0) nombre,
  @HiveField(1) selection,
  @HiveField(2) checkbox,
  @HiveField(3) radio,
}

/// Champ de formulaire
@HiveType(typeId: HiveTypeId.blockFormulaireChamp)
class FormulaireChamp {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String label;
  
  @HiveField(2)
  final ChampType type;
  
  @HiveField(3)
  final List<FormulaireOption>? options;
  
  @HiveField(4)
  final num? min;
  
  @HiveField(5)
  final num? max;
  
  @HiveField(6)
  final num? defaut;
  
  @HiveField(7)
  final num? points;

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
@HiveType(typeId: HiveTypeId.blockFormulaireOption)
class FormulaireOption {
  @HiveField(0)
  final String label;
  
  @HiveField(1)
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
@HiveType(typeId: HiveTypeId.blockFormulaireInterpretation)
class FormulaireInterpretation {
  @HiveField(0)
  final num min;
  
  @HiveField(1)
  final num max;
  
  @HiveField(2)
  final String texte;
  
  @HiveField(3)
  final String? couleur;
  
  @HiveField(4)
  final String? niveau; 

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
@HiveType(typeId: HiveTypeId.blockAlerte)
class AlerteBlock extends ProtocolBlock {
  @HiveField(0)
  final String contenu;
  
  @HiveField(1)
  final AlerteNiveau niveau;

  @HiveField(2)
  @override
  final int ordre;

  @HiveField(3)
  @override
  final String? id;

  AlerteBlock({
    required this.ordre,
    this.id,
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
@HiveType(typeId: HiveTypeId.alerteNiveau)
enum AlerteNiveau {
  @HiveField(0) info,
  @HiveField(1) attention,
  @HiveField(2) danger,
  @HiveField(3) critique,
}