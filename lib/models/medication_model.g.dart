// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicamentAdapter extends TypeAdapter<Medicament> {
  @override
  final int typeId = 0;

  @override
  Medicament read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicament(
      nom: fields[0] as String,
      nomCommercial: fields[1] as String?,
      galenique: fields[2] as String,
      indications: (fields[3] as List).cast<Indication>(),
      contreIndications: fields[4] as String?,
      surdosage: fields[5] as String?,
      aSavoir: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Medicament obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.nomCommercial)
      ..writeByte(2)
      ..write(obj.galenique)
      ..writeByte(3)
      ..write(obj.indications)
      ..writeByte(4)
      ..write(obj.contreIndications)
      ..writeByte(5)
      ..write(obj.surdosage)
      ..writeByte(6)
      ..write(obj.aSavoir);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicamentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IndicationAdapter extends TypeAdapter<Indication> {
  @override
  final int typeId = 1;

  @override
  Indication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Indication(
      label: fields[0] as String,
      posologies: (fields[1] as List).cast<Posologie>(),
    );
  }

  @override
  void write(BinaryWriter writer, Indication obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.posologies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PosologieAdapter extends TypeAdapter<Posologie> {
  @override
  final int typeId = 2;

  @override
  Posologie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Posologie(
      voie: fields[0] as String,
      doseKg: fields[1] as double?,
      doseKgMin: fields[2] as double?,
      doseKgMax: fields[3] as double?,
      tranches: (fields[4] as List?)?.cast<Tranche>(),
      unite: fields[5] as String,
      preparation: fields[6] as String,
      doseMax: fields[7] as dynamic,
      doses: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Posologie obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.voie)
      ..writeByte(1)
      ..write(obj.doseKg)
      ..writeByte(2)
      ..write(obj.doseKgMin)
      ..writeByte(3)
      ..write(obj.doseKgMax)
      ..writeByte(4)
      ..write(obj.tranches)
      ..writeByte(5)
      ..write(obj.unite)
      ..writeByte(6)
      ..write(obj.preparation)
      ..writeByte(7)
      ..write(obj.doseMax)
      ..writeByte(8)
      ..write(obj.doses);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosologieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrancheAdapter extends TypeAdapter<Tranche> {
  @override
  final int typeId = 3;

  @override
  Tranche read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tranche(
      poidsMin: fields[0] as double?,
      poidsMax: fields[1] as double?,
      ageMin: fields[2] as double?,
      ageMax: fields[3] as double?,
      doseKg: fields[4] as double?,
      doseKgMin: fields[5] as double?,
      doseKgMax: fields[6] as double?,
      doses: fields[7] as String?,
      unite: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Tranche obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.poidsMin)
      ..writeByte(1)
      ..write(obj.poidsMax)
      ..writeByte(2)
      ..write(obj.ageMin)
      ..writeByte(3)
      ..write(obj.ageMax)
      ..writeByte(4)
      ..write(obj.doseKg)
      ..writeByte(5)
      ..write(obj.doseKgMin)
      ..writeByte(6)
      ..write(obj.doseKgMax)
      ..writeByte(7)
      ..write(obj.doses)
      ..writeByte(8)
      ..write(obj.unite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrancheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
