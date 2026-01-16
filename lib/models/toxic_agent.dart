import 'package:hive/hive.dart';
import 'hive_type_id.dart';

part 'toxic_agent.g.dart';

@HiveType(typeId: HiveTypeId.toxicAgent)
class ToxicAgent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nom;

  @HiveField(2)
  final List<String> motsCles;

  @HiveField(3)
  final double? doseToxique; // Null si "à définir" ou inconnu

  @HiveField(4)
  final String unite; // "mg/kg", "mcg/kg", "UI/kg", "g/kg"

  @HiveField(5)
  final String? picCinetique;

  @HiveField(6)
  final String? demiVie;

  @HiveField(7)
  final String conduiteATenir;

  @HiveField(8)
  final String? antidoteId; // Référence vers medicaments_pediatrie.json

  @HiveField(9)
  final bool graviteExtreme;

  ToxicAgent({
    required this.id,
    required this.nom,
    this.motsCles = const [],
    this.doseToxique,
    this.unite = "mg/kg",
    this.picCinetique,
    this.demiVie,
    required this.conduiteATenir,
    this.antidoteId,
    this.graviteExtreme = false,
  });

  factory ToxicAgent.fromJson(Map<String, dynamic> json) {
    return ToxicAgent(
      id: json['id'] as String,
      nom: json['nom'] as String,
      motsCles: List<String>.from(json['mots_cles'] ?? []),
      doseToxique: (json['dose_toxique'] as num?)?.toDouble(),
      unite: json['unite'] ?? "mg/kg",
      picCinetique: json['pic_cinetique'],
      demiVie: json['demi_vie'],
      conduiteATenir: json['conduite_a_tenir'] ?? "Avis CAP indispensable.",
      antidoteId: json['antidote_id'],
      graviteExtreme: json['gravite_extreme'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'mots_cles': motsCles,
    'dose_toxique': doseToxique,
    'unite': unite,
    'pic_cinetique': picCinetique,
    'demi_vie': demiVie,
    'conduite_a_tenir': conduiteATenir,
    'antidote_id': antidoteId,
    'gravite_extreme': graviteExtreme,
  };
}