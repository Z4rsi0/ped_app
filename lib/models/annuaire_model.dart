// Modèle de données pour l'annuaire
class Annuaire {
  final List<Service> interne;
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

class Service {
  final String nom;
  final List<Contact> contacts;
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

class Contact {
  final String? label;
  final String numero;
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