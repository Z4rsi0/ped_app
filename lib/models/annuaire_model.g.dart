// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annuaire_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnuaireAdapter extends TypeAdapter<Annuaire> {
  @override
  final int typeId = 101;

  @override
  Annuaire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Annuaire(
      interne: (fields[0] as List).cast<Service>(),
      externe: (fields[1] as List).cast<Service>(),
    );
  }

  @override
  void write(BinaryWriter writer, Annuaire obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.interne)
      ..writeByte(1)
      ..write(obj.externe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnuaireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ServiceAdapter extends TypeAdapter<Service> {
  @override
  final int typeId = 102;

  @override
  Service read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Service(
      nom: fields[0] as String,
      contacts: (fields[1] as List).cast<Contact>(),
      description: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Service obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.contacts)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 103;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      label: fields[0] as String?,
      numero: fields[1] as String,
      type: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.numero)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
