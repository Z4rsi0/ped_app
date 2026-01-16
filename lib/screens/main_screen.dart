import 'package:flutter/material.dart';
import 'therapeutique_screen.dart';
import 'protocoles_screen.dart';
import 'pocus_screen.dart'; // Import du nouvel écran
import 'annuaire_screen.dart';
import '../services/data_sync_service.dart';
import '../widgets/global_weight_selector.dart';
import 'tox_screen.dart'; // Ajoute cet import en haut

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Protocoles par défaut
  bool _isSyncing = false;

  final List<Widget> _pages = const [
    TherapeutiqueScreen(),
    ProtocolesScreen(),
    PocusScreen(), // Nouvel onglet
    AnnuaireScreen(),
    ToxScreen(), // Ajoute l'écran de toxicologie ici
  ];

  final List<String> _titles = [
    'Thérapeutique', 
    'Protocoles', 
    'Pocus / Écho', // Titre Pocus
    'Annuaire',
    'Toxicologie', // Titre Toxicologie
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundSync();
    });
  }

  Future<void> _startBackgroundSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    
    await DataSyncService.syncAllData();
    
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On cache le sélecteur de poids uniquement pour l'Annuaire (index 3)
    final showWeightSelector = _selectedIndex != 2 && _selectedIndex != 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: showWeightSelector 
            ? const [Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: GlobalWeightSelector(),
              )]
            : null,
        bottom: _isSyncing 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              ) 
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Médicaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Protocoles',
          ),
          // Nouvel item de navigation
          NavigationDestination(
            icon: Icon(Icons.broadcast_on_personal_outlined), // ou Icons.waves
            selectedIcon: Icon(Icons.broadcast_on_personal),
            label: 'Pocus',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Annuaire',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Toxicologie',
          ),
        ],
      ),
    );
  }
}