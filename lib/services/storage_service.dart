import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_model.dart';
import '../models/protocol_model.dart';
import '../models/annuaire_model.dart';
import '../models/toxic_agent.dart'; // Import du modèle ToxicAgent

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Noms des boîtes (Clés de stockage)
  static const String _boxMedicaments = 'medicamentsBox';
  static const String _boxProtocols = 'protocolsBox';
  static const String _boxAnnuaire = 'annuaireBox';
  static const String _boxPocus = 'pocusBox';
  static const String _boxToxics = 'toxicsBox'; // NOUVEAU

  // Variables des boîtes
  Box<Medicament>? _medicamentBox;
  Box<Protocol>? _protocolBox;
  Box<Annuaire>? _annuaireBox;
  Box<Protocol>? _pocusBox;
  Box<ToxicAgent>? _toxicsBox; // NOUVEAU

  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
    debugPrint('📦 StorageService: Initialisé.');
  }

  void _registerAdapters() {
    // --- Domaine Médicament ---
    Hive.registerAdapter(MedicamentAdapter());
    Hive.registerAdapter(IndicationAdapter());
    Hive.registerAdapter(PosologieAdapter());
    Hive.registerAdapter(TrancheAdapter());

    // --- Domaine Annuaire ---
    Hive.registerAdapter(AnnuaireAdapter());
    Hive.registerAdapter(ServiceAdapter());
    Hive.registerAdapter(ContactAdapter());

    // --- Domaine Protocole & Bloc ---
    Hive.registerAdapter(ProtocolAdapter());
    Hive.registerAdapter(BlockTypeAdapter());
    Hive.registerAdapter(SectionBlockAdapter());
    Hive.registerAdapter(TexteBlockAdapter());
    Hive.registerAdapter(TexteFormatAdapter());
    Hive.registerAdapter(TableauBlockAdapter());
    Hive.registerAdapter(ImageBlockAdapter());
    Hive.registerAdapter(MedicamentBlockAdapter());
    
    // --- Domaine Formulaire / Calculateur ---
    Hive.registerAdapter(FormulaireBlockAdapter());
    Hive.registerAdapter(FormulaireChampAdapter());
    Hive.registerAdapter(ChampTypeAdapter());
    Hive.registerAdapter(FormulaireOptionAdapter());
    Hive.registerAdapter(FormulaireInterpretationAdapter());
    
    // --- Domaine Alerte ---
    Hive.registerAdapter(AlerteBlockAdapter());
    Hive.registerAdapter(AlerteNiveauAdapter());

    // --- NOUVEAU : Domaine Toxicologie ---
    Hive.registerAdapter(ToxicAgentAdapter());
  }

  Future<void> _openBoxes() async {
    // Ouverture parallèle pour gagner du temps
    await Future.wait([
      _openMedicamentBox(),
      _openProtocolBox(),
      _openAnnuaireBox(),
      _openPocusBox(),
      _openToxicsBox(), // NOUVEAU
    ]);
  }

  // Wrappers d'ouverture individuels pour gérer l'assignation proprement
  Future<void> _openMedicamentBox() async => _medicamentBox = await Hive.openBox<Medicament>(_boxMedicaments);
  Future<void> _openProtocolBox() async => _protocolBox = await Hive.openBox<Protocol>(_boxProtocols);
  Future<void> _openAnnuaireBox() async => _annuaireBox = await Hive.openBox<Annuaire>(_boxAnnuaire);
  Future<void> _openPocusBox() async => _pocusBox = await Hive.openBox<Protocol>(_boxPocus);
  // NOUVEAU
  Future<void> _openToxicsBox() async => _toxicsBox = await Hive.openBox<ToxicAgent>(_boxToxics);

  // --- GETTERS (Données brutes) ---
  List<Medicament> getMedicaments() => _medicamentBox?.values.toList() ?? [];
  List<Protocol> getProtocols() => _protocolBox?.values.toList() ?? [];
  Annuaire? getAnnuaire() => _annuaireBox != null && _annuaireBox!.isNotEmpty ? _annuaireBox!.getAt(0) : null;
  List<Protocol> getPocusProtocols() => _pocusBox?.values.toList() ?? [];
  // NOUVEAU
  List<ToxicAgent> getToxicAgents() => _toxicsBox?.values.toList() ?? [];

  // --- LISTENABLES (Pour la réactivité UI - ValueListenableBuilder) ---
  ValueListenable<Box<Medicament>> get medicamentListenable => _medicamentBox!.listenable();
  ValueListenable<Box<Protocol>> get protocolListenable => _protocolBox!.listenable();
  ValueListenable<Box<Annuaire>> get annuaireListenable => _annuaireBox!.listenable();
  ValueListenable<Box<Protocol>> get pocusListenable => _pocusBox!.listenable();
  // NOUVEAU
  ValueListenable<Box<ToxicAgent>> get toxicsListenable => _toxicsBox!.listenable();

  // --- SETTERS ---
  Future<void> saveMedicaments(List<Medicament> list) async {
    await _medicamentBox?.clear();
    await _medicamentBox?.addAll(list);
  }

  Future<void> saveProtocols(List<Protocol> list) async {
    await _protocolBox?.clear();
    await _protocolBox?.addAll(list);
  }
  
  Future<void> savePocusProtocols(List<Protocol> list) async {
    await _pocusBox?.clear();
    await _pocusBox?.addAll(list);
  }

  Future<void> saveAnnuaire(Annuaire annuaire) async {
    await _annuaireBox?.clear();
    await _annuaireBox?.add(annuaire);
  }

  // NOUVEAU : Sauvegarde des toxiques
  Future<void> saveToxicAgents(List<ToxicAgent> list) async {
    await _toxicsBox?.clear();
    await _toxicsBox?.addAll(list);
  }
}