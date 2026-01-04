import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Noms des boîtes (Boxes)
  static const String _boxMedicaments = 'medicamentsBox';
  static const String _boxProtocols = 'protocolsBox';
  static const String _boxAnnuaire = 'annuaireBox';

  Box<Medicament>? _medicamentBox;
  Box<Protocol>? _protocolBox;
  Box<Annuaire>? _annuaireBox;

  /// Initialise Hive, enregistre les adapters et ouvre les boîtes
  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
    debugPrint('📦 StorageService: Initialisé et prêt.');
  }

  void _registerAdapters() {
    // Il faut enregistrer TOUS les adapters générés.
    // L'ordre n'importe pas, mais il ne faut en oublier aucun.
    
    // Domaine Médicament
    Hive.registerAdapter(MedicamentAdapter());
    Hive.registerAdapter(IndicationAdapter());
    Hive.registerAdapter(PosologieAdapter());
    Hive.registerAdapter(TrancheAdapter());

    // Domaine Annuaire
    Hive.registerAdapter(AnnuaireAdapter());
    Hive.registerAdapter(ServiceAdapter());
    Hive.registerAdapter(ContactAdapter());

    // Domaine Protocole (Le plus gros morceau)
    Hive.registerAdapter(ProtocolAdapter());
    Hive.registerAdapter(BlockTypeAdapter()); // L'Enum
    // Hive.registerAdapter(ProtocolBlockAdapter()); // Pas nécessaire car classe abstraite, on enregistre les enfants
    Hive.registerAdapter(SectionBlockAdapter());
    Hive.registerAdapter(TexteBlockAdapter());
    Hive.registerAdapter(TexteFormatAdapter());
    Hive.registerAdapter(TableauBlockAdapter());
    Hive.registerAdapter(ImageBlockAdapter());
    Hive.registerAdapter(MedicamentBlockAdapter());
    
    // Domaine Formulaire / Alertes
    Hive.registerAdapter(FormulaireBlockAdapter());
    Hive.registerAdapter(FormulaireChampAdapter());
    Hive.registerAdapter(ChampTypeAdapter()); // L'Enum
    Hive.registerAdapter(FormulaireOptionAdapter());
    Hive.registerAdapter(FormulaireInterpretationAdapter());
    Hive.registerAdapter(AlerteBlockAdapter());
    Hive.registerAdapter(AlerteNiveauAdapter()); // L'Enum
  }

  Future<void> _openBoxes() async {
    _medicamentBox = await Hive.openBox<Medicament>(_boxMedicaments);
    _protocolBox = await Hive.openBox<Protocol>(_boxProtocols);
    _annuaireBox = await Hive.openBox<Annuaire>(_boxAnnuaire);
  }

  // --- MÉTHODES D'ACCÈS (API) ---

  // 1. Médicaments
  List<Medicament> getMedicaments() {
    return _medicamentBox?.values.toList() ?? [];
  }

  Future<void> saveMedicaments(List<Medicament> list) async {
    await _medicamentBox?.clear();
    await _medicamentBox?.addAll(list);
    debugPrint('💊 ${_medicamentBox?.length} médicaments sauvegardés localement.');
  }

  // 2. Protocoles
  List<Protocol> getProtocols() {
    return _protocolBox?.values.toList() ?? [];
  }

  Future<void> saveProtocols(List<Protocol> list) async {
    // Stratégie simple : on remplace tout pour l'instant.
    // Pour une synchro plus fine (delta), on verra plus tard.
    await _protocolBox?.clear();
    await _protocolBox?.addAll(list);
    debugPrint('📜 ${_protocolBox?.length} protocoles sauvegardés localement.');
  }

  // 3. Annuaire
  Annuaire? getAnnuaire() {
    if (_annuaireBox == null || _annuaireBox!.isEmpty) return null;
    return _annuaireBox!.getAt(0);
  }

  Future<void> saveAnnuaire(Annuaire annuaire) async {
    await _annuaireBox?.clear();
    await _annuaireBox?.add(annuaire);
    debugPrint('📞 Annuaire sauvegardé localement.');
  }
  
  // Utilitaire pour tout effacer (Logout ou Debug)
  Future<void> clearAll() async {
    await _medicamentBox?.clear();
    await _protocolBox?.clear();
    await _annuaireBox?.clear();
  }
}