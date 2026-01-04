import 'package:hive/hive.dart';
import 'hive_type_id.dart';

part 'annuaire_model.g.dart';

// Modèle de données pour l'annuaire
@HiveType(typeId: HiveTypeId.annuaire)
class Annuaire {
  @HiveField(0)
  final List<Service> interne;
  
  @HiveField(1)
  final List<Service> externe;

  Annuaire({
    required this.interne,
    required this.externe,
  });

  factory Annuaire.fromJson(Map<String, dynamic> json) {
    return Annuaire(
      interne: (json['interne'] as List<dynamic>?)
              ?.map((s) => Service.fromJson(s))
              .toList() ??
          [],
      externe: (json['externe'] as List<dynamic>?)
              ?.map((s) => Service.fromJson(s))
              .toList() ??
          [],
    );
  }
}

@HiveType(typeId: HiveTypeId.service)
class Service {
  @HiveField(0)
  final String nom;
  
  @HiveField(1)
  final List<Contact> contacts;
  
  @HiveField(2)
  final String? description;

  Service({
    required this.nom,
    required this.contacts,
    this.description,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      nom: json['nom'] ?? '',
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((c) => Contact.fromJson(c))
              .toList() ??
          [],
      description: json['description'],
    );
  }
}

@HiveType(typeId: HiveTypeId.contact)
class Contact {
  @HiveField(0)
  final String? label;
  
  @HiveField(1)
  final String numero;
  
  @HiveField(2)
  final String? type; // "fixe", "mobile", "fax", "bip"

  Contact({
    this.label,
    required this.numero,
    this.type,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      label: json['label'],
      numero: json['numero'] ?? '',
      type: json['type'],
    );
  }
}