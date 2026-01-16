// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toxic_agent.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ToxicAgentAdapter extends TypeAdapter<ToxicAgent> {
  @override
  final int typeId = 50;

  @override
  ToxicAgent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToxicAgent(
      id: fields[0] as String,
      nom: fields[1] as String,
      motsCles: (fields[2] as List).cast<String>(),
      doseToxique: fields[3] as double?,
      unite: fields[4] as String,
      picCinetique: fields[5] as String?,
      demiVie: fields[6] as String?,
      conduiteATenir: fields[7] as String,
      antidoteId: fields[8] as String?,
      graviteExtreme: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ToxicAgent obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.motsCles)
      ..writeByte(3)
      ..write(obj.doseToxique)
      ..writeByte(4)
      ..write(obj.unite)
      ..writeByte(5)
      ..write(obj.picCinetique)
      ..writeByte(6)
      ..write(obj.demiVie)
      ..writeByte(7)
      ..write(obj.conduiteATenir)
      ..writeByte(8)
      ..write(obj.antidoteId)
      ..writeByte(9)
      ..write(obj.graviteExtreme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToxicAgentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
