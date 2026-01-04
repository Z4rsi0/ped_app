import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'therapeutique.dart';
import 'annuaire.dart';
import 'screens/protocoles_screen.dart';
import 'providers/weight_provider.dart';
import 'services/data_sync_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Chargement des variables d'environnement
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Fichier .env chargé');
  } catch (e) {
    debugPrint('⚠️ Fichier .env non trouvé (fonctionnement sans token)');
  }

  // 2. Initialisation du Moteur de Données (Hive)
  // C'est ici que les données sont chargées en mémoire depuis le disque.
  try {
    await StorageService().init();
  } catch (e) {
    debugPrint('❌ Erreur critique init StorageService: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => WeightProvider(),
      child: const PediatricApp(),
    ),
  );
}

class PediatricApp extends StatelessWidget {
  const PediatricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thérapeutique Pédiatrique',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, 
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initialisation...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    // 1. Vérification réseau
    setState(() => _status = 'Vérification de la connexion...');
    final hasInternet = await DataSyncService.hasInternetConnection();

    // 2. Synchronisation (Mise à jour du cache Hive si réseau dispo)
    if (hasInternet) {
      if (!mounted) return;
      setState(() => _status = 'Mise à jour des données...');
      
      // Cette étape met à jour Hive en arrière-plan
      final result = await DataSyncService.syncAllData();
      
      if (!mounted) return;
      if (result.hasErrors) {
        setState(() {
          _status = result.message;
          _hasError = true;
        });
        // Petit délai pour laisser l'utilisateur lire l'erreur
        await Future.delayed(const Duration(seconds: 2));
      } else {
        setState(() => _status = result.message);
        await Future.delayed(const Duration(seconds: 1));
      }
    } else {
      // Mode Hors Ligne
      if (!mounted) return;
      setState(() => _status = 'Mode hors ligne');
      // On utilise simplement les données déjà présentes dans Hive (chargées au main)
      await Future.delayed(const Duration(seconds: 1));
    }

    // NOTE : Plus besoin de "Chargement des médicaments/protocoles" ici.
    // StorageService().init() l'a déjà fait au démarrage de l'app.

    // 3. Navigation
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'MASSIO',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text('Thérapeutique Pédiatrique', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 48),
              if (!_hasError)
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
              else
                const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasError ? Colors.orange.shade200 : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  final List<String> _titles = ['Thérapeutique', 'Protocoles', 'Annuaire'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 2 ? null : const [GlobalWeightSelector()],
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

class GlobalWeightSelector extends StatelessWidget {
  const GlobalWeightSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, _) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton.icon(
            onPressed: () => _showWeightDialog(context, weightProvider),
            icon: const Icon(Icons.monitor_weight, size: 18),
            label: Text(
              weightProvider.weight != null ? '${weightProvider.formattedWeight} kg' : 'Poids',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  void _showWeightDialog(BuildContext context, WeightProvider provider) {
    double tempWeight = provider.weight ?? 10.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Sélection du poids'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: tempWeight,
                  min: 0.4,
                  max: 50.0,
                  divisions: 496,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value < 10) {
                        tempWeight = (value * 10).round() / 10;
                      } else {
                        tempWeight = value.roundToDouble();
                      }
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickWeightButton(
                      label: '-1',
                      onPressed: () => setDialogState(() => tempWeight = (tempWeight - 1).clamp(0.4, 50.0)),
                    ),
                    _QuickWeightButton(
                      label: '-0.1',
                      onPressed: () => setDialogState(() => tempWeight = (((tempWeight - 0.1) * 10).round() / 10).clamp(0.4, 50.0)),
                    ),
                    _QuickWeightButton(
                      label: '+0.1',
                      onPressed: () => setDialogState(() => tempWeight = (((tempWeight + 0.1) * 10).round() / 10).clamp(0.4, 50.0)),
                    ),
                    _QuickWeightButton(
                      label: '+1',
                      onPressed: () => setDialogState(() => tempWeight = (tempWeight + 1).clamp(0.4, 50.0)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.clearWeight();
                  Navigator.of(context).pop();
                },
                child: const Text('Effacer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  provider.setWeight(tempWeight);
                  Navigator.of(context).pop();
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickWeightButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _QuickWeightButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label),
    );
  }
}