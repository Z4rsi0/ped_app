import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'therapeutique.dart';
import 'annuaire.dart';
import 'screens/protocoles_screen.dart';
import 'providers/weight_provider.dart';
import 'services/data_sync_service.dart';
import 'services/medicament_resolver.dart';
import 'services/protocol_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger le fichier .env (contient GITHUB_TOKEN)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Fichier .env chargé');
  } catch (e) {
    debugPrint('⚠️ Fichier .env non trouvé (fonctionnement sans token)');
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
    // Vérifier connexion Internet
    setState(() => _status = 'Vérification de la connexion...');
    final hasInternet = await DataSyncService.hasInternetConnection();

    if (hasInternet) {
      // Synchroniser les données
      setState(() => _status = 'Mise à jour des données...');
      final result = await DataSyncService.syncAllData();

      if (result.hasErrors) {
        setState(() {
          _status = result.message;
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 2));
      } else {
        setState(() => _status = result.message);
        await Future.delayed(const Duration(seconds: 1));
      }
    } else {
      setState(
          () => _status = 'Mode hors ligne - Utilisation des données locales');
      await Future.delayed(const Duration(seconds: 1));
    }

    // Précharger les médicaments pour le resolver
    setState(() => _status = 'Chargement des médicaments...');
    try {
      await MedicamentResolver().loadMedicaments();
    } catch (e) {
      debugPrint('⚠️ Erreur préchargement médicaments: $e');
    }

    // Charger les protocoles
    setState(() => _status = 'Chargement des protocoles...');
    try {
      await ProtocolService().loadProtocols();
    } catch (e) {
      debugPrint('⚠️ Erreur préchargement protocoles: $e');
    }

    // Navigation vers l'écran principal
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
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'MASSIO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thérapeutique Pédiatrique',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              if (!_hasError)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
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

  final List<String> _titles = [
    'Thérapeutique Pédiatrique',
    'Protocoles',
    'Annuaire',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _selectedIndex == 2
            ? null
            : const [
                GlobalWeightSelector(),
              ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

/// Widget global pour sélectionner le poids (version compacte pour l'AppBar)
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
              weightProvider.weight != null
                  ? '${weightProvider.formattedWeight} kg'
                  : 'Poids',
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: tempWeight,
                  min: 0.4,
                  max: 100.0,
                  divisions: 996,
                  onChanged: (value) {
                    setDialogState(() {
                      // Arrondir selon les tranches
                      if (value < 10) {
                        tempWeight = (value * 10).round() / 10; // 0.1 kg
                      } else {
                        tempWeight = value.roundToDouble(); // 1 kg
                      }
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickWeightButton(
                      label: '-1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = (tempWeight - 1).clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '-0.1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = ((tempWeight - 0.1) * 10).round() / 10;
                          tempWeight = tempWeight.clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '+0.1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = ((tempWeight + 0.1) * 10).round() / 10;
                          tempWeight = tempWeight.clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '+1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = (tempWeight + 1).clamp(0.4, 100.0);
                        });
                      },
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

  const _QuickWeightButton({
    required this.label,
    required this.onPressed,
  });

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