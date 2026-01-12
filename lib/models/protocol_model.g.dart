// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProtocolAdapter extends TypeAdapter<Protocol> {
  @override
  final int typeId = 20;

  @override
  Protocol read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Protocol(
      titre: fields[0] as String,
      description: fields[1] as String,
      auteur: fields[2] as String?,
      version: fields[3] as String?,
      dateModification: fields[4] as DateTime?,
      blocs: (fields[5] as List).cast<ProtocolBlock>(),
      categorie: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Protocol obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.auteur)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.dateModification)
      ..writeByte(5)
      ..write(obj.blocs)
      ..writeByte(6)
      ..write(obj.categorie);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtocolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionBlockAdapter extends TypeAdapter<SectionBlock> {
  @override
  final int typeId = 30;

  @override
  SectionBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectionBlock(
      ordre: fields[4] as int,
      id: fields[5] as String?,
      titre: fields[0] as String,
      temps: fields[1] as String?,
      initialementOuvert: fields[2] as bool,
      contenu: (fields[3] as List).cast<ProtocolBlock>(),
    );
  }

  @override
  void write(BinaryWriter writer, SectionBlock obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.temps)
      ..writeByte(2)
      ..write(obj.initialementOuvert)
      ..writeByte(3)
      ..write(obj.contenu)
      ..writeByte(4)
      ..write(obj.ordre)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TexteBlockAdapter extends TypeAdapter<TexteBlock> {
  @override
  final int typeId = 31;

  @override
  TexteBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TexteBlock(
      ordre: fields[2] as int,
      id: fields[3] as String?,
      contenu: fields[0] as String,
      format: fields[1] as TexteFormat?,
    );
  }

  @override
  void write(BinaryWriter writer, TexteBlock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.contenu)
      ..writeByte(1)
      ..write(obj.format)
      ..writeByte(2)
      ..write(obj.ordre)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TexteBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TexteFormatAdapter extends TypeAdapter<TexteFormat> {
  @override
  final int typeId = 32;

  @override
  TexteFormat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TexteFormat(
      gras: fields[0] as bool,
      italique: fields[1] as bool,
      souligne: fields[2] as bool,
      couleur: fields[3] as String?,
      taillePolicePx: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TexteFormat obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.gras)
      ..writeByte(1)
      ..write(obj.italique)
      ..writeByte(2)
      ..write(obj.souligne)
      ..writeByte(3)
      ..write(obj.couleur)
      ..writeByte(4)
      ..write(obj.taillePolicePx);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TexteFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableauBlockAdapter extends TypeAdapter<TableauBlock> {
  @override
  final int typeId = 33;

  @override
  TableauBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TableauBlock(
      ordre: fields[4] as int,
      id: fields[5] as String?,
      titre: fields[0] as String?,
      colonnes: (fields[1] as List).cast<String>(),
      lignes: (fields[2] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList(),
      avecEntete: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TableauBlock obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.colonnes)
      ..writeByte(2)
      ..write(obj.lignes)
      ..writeByte(3)
      ..write(obj.avecEntete)
      ..writeByte(4)
      ..write(obj.ordre)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableauBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageBlockAdapter extends TypeAdapter<ImageBlock> {
  @override
  final int typeId = 34;

  @override
  ImageBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageBlock(
      ordre: fields[4] as int,
      id: fields[5] as String?,
      source: fields[0] as String,
      estBase64: fields[1] as bool,
      legende: fields[2] as String?,
      largeurPourcent: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageBlock obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.source)
      ..writeByte(1)
      ..write(obj.estBase64)
      ..writeByte(2)
      ..write(obj.legende)
      ..writeByte(3)
      ..write(obj.largeurPourcent)
      ..writeByte(4)
      ..write(obj.ordre)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicamentBlockAdapter extends TypeAdapter<MedicamentBlock> {
  @override
  final int typeId = 35;

  @override
  MedicamentBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicamentBlock(
      ordre: fields[4] as int,
      id: fields[5] as String?,
      nomMedicament: fields[0] as String,
      indication: fields[1] as String,
      voie: fields[2] as String?,
      commentaire: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicamentBlock obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nomMedicament)
      ..writeByte(1)
      ..write(obj.indication)
      ..writeByte(2)
      ..write(obj.voie)
      ..writeByte(3)
      ..write(obj.commentaire)
      ..writeByte(4)
      ..write(obj.ordre)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicamentBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaireBlockAdapter extends TypeAdapter<FormulaireBlock> {
  @override
  final int typeId = 36;

  @override
  FormulaireBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaireBlock(
      ordre: fields[5] as int,
      id: fields[6] as String?,
      titre: fields[0] as String,
      description: fields[1] as String?,
      champs: (fields[2] as List).cast<FormulaireChamp>(),
      formuleCalcul: fields[3] as String?,
      interpretations: (fields[4] as List?)?.cast<FormulaireInterpretation>(),
    );
  }

  @override
  void write(BinaryWriter writer, FormulaireBlock obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.champs)
      ..writeByte(3)
      ..write(obj.formuleCalcul)
      ..writeByte(4)
      ..write(obj.interpretations)
      ..writeByte(5)
      ..write(obj.ordre)
      ..writeByte(6)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaireBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaireChampAdapter extends TypeAdapter<FormulaireChamp> {
  @override
  final int typeId = 37;

  @override
  FormulaireChamp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaireChamp(
      id: fields[0] as String,
      label: fields[1] as String,
      type: fields[2] as ChampType,
      options: (fields[3] as List?)?.cast<FormulaireOption>(),
      min: fields[4] as num?,
      max: fields[5] as num?,
      defaut: fields[6] as num?,
      points: fields[7] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, FormulaireChamp obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.options)
      ..writeByte(4)
      ..write(obj.min)
      ..writeByte(5)
      ..write(obj.max)
      ..writeByte(6)
      ..write(obj.defaut)
      ..writeByte(7)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaireChampAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaireOptionAdapter extends TypeAdapter<FormulaireOption> {
  @override
  final int typeId = 38;

  @override
  FormulaireOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaireOption(
      label: fields[0] as String,
      valeur: fields[1] as num,
    );
  }

  @override
  void write(BinaryWriter writer, FormulaireOption obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.valeur);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaireOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormulaireInterpretationAdapter
    extends TypeAdapter<FormulaireInterpretation> {
  @override
  final int typeId = 39;

  @override
  FormulaireInterpretation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormulaireInterpretation(
      min: fields[0] as num,
      max: fields[1] as num,
      texte: fields[2] as String,
      couleur: fields[3] as String?,
      niveau: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FormulaireInterpretation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.min)
      ..writeByte(1)
      ..write(obj.max)
      ..writeByte(2)
      ..write(obj.texte)
      ..writeByte(3)
      ..write(obj.couleur)
      ..writeByte(4)
      ..write(obj.niveau);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaireInterpretationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlerteBlockAdapter extends TypeAdapter<AlerteBlock> {
  @override
  final int typeId = 40;

  @override
  AlerteBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlerteBlock(
      ordre: fields[2] as int,
      id: fields[3] as String?,
      contenu: fields[0] as String,
      niveau: fields[1] as AlerteNiveau,
    );
  }

  @override
  void write(BinaryWriter writer, AlerteBlock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.contenu)
      ..writeByte(1)
      ..write(obj.niveau)
      ..writeByte(2)
      ..write(obj.ordre)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlerteBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockTypeAdapter extends TypeAdapter<BlockType> {
  @override
  final int typeId = 43;

  @override
  BlockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BlockType.section;
      case 1:
        return BlockType.texte;
      case 2:
        return BlockType.tableau;
      case 3:
        return BlockType.image;
      case 4:
        return BlockType.medicament;
      case 5:
        return BlockType.formulaire;
      case 6:
        return BlockType.alerte;
      default:
        return BlockType.section;
    }
  }

  @override
  void write(BinaryWriter writer, BlockType obj) {
    switch (obj) {
      case BlockType.section:
        writer.writeByte(0);
        break;
      case BlockType.texte:
        writer.writeByte(1);
        break;
      case BlockType.tableau:
        writer.writeByte(2);
        break;
      case BlockType.image:
        writer.writeByte(3);
        break;
      case BlockType.medicament:
        writer.writeByte(4);
        break;
      case BlockType.formulaire:
        writer.writeByte(5);
        break;
      case BlockType.alerte:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChampTypeAdapter extends TypeAdapter<ChampType> {
  @override
  final int typeId = 42;

  @override
  ChampType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChampType.nombre;
      case 1:
        return ChampType.selection;
      case 2:
        return ChampType.checkbox;
      case 3:
        return ChampType.radio;
      default:
        return ChampType.nombre;
    }
  }

  @override
  void write(BinaryWriter writer, ChampType obj) {
    switch (obj) {
      case ChampType.nombre:
        writer.writeByte(0);
        break;
      case ChampType.selection:
        writer.writeByte(1);
        break;
      case ChampType.checkbox:
        writer.writeByte(2);
        break;
      case ChampType.radio:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChampTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlerteNiveauAdapter extends TypeAdapter<AlerteNiveau> {
  @override
  final int typeId = 41;

  @override
  AlerteNiveau read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlerteNiveau.info;
      case 1:
        return AlerteNiveau.attention;
      case 2:
        return AlerteNiveau.danger;
      case 3:
        return AlerteNiveau.critique;
      default:
        return AlerteNiveau.info;
    }
  }

  @override
  void write(BinaryWriter writer, AlerteNiveau obj) {
    switch (obj) {
      case AlerteNiveau.info:
        writer.writeByte(0);
        break;
      case AlerteNiveau.attention:
        writer.writeByte(1);
        break;
      case AlerteNiveau.danger:
        writer.writeByte(2);
        break;
      case AlerteNiveau.critique:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlerteNiveauAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
