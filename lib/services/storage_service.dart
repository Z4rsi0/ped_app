import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _boxMedicaments = 'medicamentsBox';
  static const String _boxProtocols = 'protocolsBox';
  static const String _boxAnnuaire = 'annuaireBox';
  // NOUVEAU : Nom de la boîte Pocus
  static const String _boxPocus = 'pocusBox'; 

  Box<Medicament>? _medicamentBox;
  Box<Protocol>? _protocolBox;
  Box<Annuaire>? _annuaireBox;
  // NOUVEAU : Variable pour la boîte
  Box<Protocol>? _pocusBox; 

  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
    debugPrint('📦 StorageService: Initialisé.');
  }

  void _registerAdapters() {
    // ... Tes adapters existants ...
    Hive.registerAdapter(MedicamentAdapter());
    Hive.registerAdapter(IndicationAdapter());
    Hive.registerAdapter(PosologieAdapter());
    Hive.registerAdapter(TrancheAdapter());
    Hive.registerAdapter(AnnuaireAdapter());
    Hive.registerAdapter(ServiceAdapter());
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(ProtocolAdapter());
    Hive.registerAdapter(BlockTypeAdapter());
    Hive.registerAdapter(SectionBlockAdapter());
    Hive.registerAdapter(TexteBlockAdapter());
    Hive.registerAdapter(TexteFormatAdapter());
    Hive.registerAdapter(TableauBlockAdapter());
    Hive.registerAdapter(ImageBlockAdapter());
    Hive.registerAdapter(MedicamentBlockAdapter());
    Hive.registerAdapter(FormulaireBlockAdapter());
    Hive.registerAdapter(FormulaireChampAdapter());
    Hive.registerAdapter(ChampTypeAdapter());
    Hive.registerAdapter(FormulaireOptionAdapter());
    Hive.registerAdapter(FormulaireInterpretationAdapter());
    Hive.registerAdapter(AlerteBlockAdapter());
    Hive.registerAdapter(AlerteNiveauAdapter());
  }

  Future<void> _openBoxes() async {
    _medicamentBox = await Hive.openBox<Medicament>(_boxMedicaments);
    _protocolBox = await Hive.openBox<Protocol>(_boxProtocols);
    _annuaireBox = await Hive.openBox<Annuaire>(_boxAnnuaire);
    // NOUVEAU : Ouverture de la boîte Pocus (stocke aussi des objets Protocol)
    _pocusBox = await Hive.openBox<Protocol>(_boxPocus); 
  }

  // --- GETTERS (Données brutes) ---
  List<Medicament> getMedicaments() => _medicamentBox?.values.toList() ?? [];
  List<Protocol> getProtocols() => _protocolBox?.values.toList() ?? [];
  Annuaire? getAnnuaire() => _annuaireBox != null && _annuaireBox!.isNotEmpty ? _annuaireBox!.getAt(0) : null;
  // NOUVEAU : Getter Pocus
  List<Protocol> getPocusProtocols() => _pocusBox?.values.toList() ?? [];

  // --- LISTENABLES (Pour la réactivité UI) ---
  ValueListenable<Box<Medicament>> get medicamentListenable => _medicamentBox!.listenable();
  ValueListenable<Box<Protocol>> get protocolListenable => _protocolBox!.listenable();
  ValueListenable<Box<Annuaire>> get annuaireListenable => _annuaireBox!.listenable();
  // NOUVEAU : Listenable Pocus
  ValueListenable<Box<Protocol>> get pocusListenable => _pocusBox!.listenable();

  // --- SETTERS ---
  Future<void> saveMedicaments(List<Medicament> list) async {
    await _medicamentBox?.clear();
    await _medicamentBox?.addAll(list);
  }

  Future<void> saveProtocols(List<Protocol> list) async {
    await _protocolBox?.clear();
    await _protocolBox?.addAll(list);
  }
  
  // NOUVEAU : Setter Pocus
  Future<void> savePocusProtocols(List<Protocol> list) async {
    await _pocusBox?.clear();
    await _pocusBox?.addAll(list);
  }

  Future<void> saveAnnuaire(Annuaire annuaire) async {
    await _annuaireBox?.clear();
    await _annuaireBox?.add(annuaire);
  }
}