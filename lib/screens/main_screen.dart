import 'package:flutter/material.dart';
import 'therapeutique_screen.dart';
import 'protocoles_screen.dart';
import 'annuaire_screen.dart';
import '../services/data_sync_service.dart';
import '../widgets/global_weight_selector.dart';

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
    AnnuaireScreen(),
  ];

  final List<String> _titles = ['Thérapeutique', 'Protocoles', 'Annuaire'];

  @override
  void initState() {
    super.initState();
    // Lancement de la synchro après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundSync();
    });
  }

  Future<void> _startBackgroundSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    
    // Cette méthode ne bloque pas l'UI. Les ValueListenableBuilder dans les écrans
    // mettront à jour l'affichage dès que les données arrivent.
    await DataSyncService.syncAllData();
    
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 2 
            ? null 
            : const [Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: GlobalWeightSelector(),
              )],
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
            label: 'Thérapeutique',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Protocoles',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Annuaire',
          ),
        ],
      ),
    );
  }
}