import 'package:flutter/material.dart';
import 'therapeutique.dart';
import 'annuaire.dart';
import 'protocoles.dart';

void main() {
  runApp(const PediatricApp());
}

class PediatricApp extends StatelessWidget {
  const PediatricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thérapeutique Pédiatrique',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TherapeutiqueScreen(),
    const ProtocolesScreen(),
    const AnnuaireScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication),
            label: 'Thérapeutique',
          ),
          NavigationDestination(
            icon: Icon(Icons.description),
            label: 'Protocoles',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts),
            label: 'Annuaire',
          ),
        ],
      ),
    );
  }
}