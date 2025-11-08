import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'therapeutique.dart';
import 'annuaire.dart';
import 'protocoles.dart';
import 'providers/weight_provider.dart';
import 'services/data_sync_service.dart';

void main() {
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
      }
    } else {
      setState(() => _status = 'Mode hors ligne - Utilisation des données locales');
      await Future.delayed(const Duration(seconds: 1));
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
              Icon(
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
        actions: const [
          GlobalWeightSelector(),
        ],
      ),
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

class GlobalWeightSelector extends StatelessWidget {
  const GlobalWeightSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_weight, size: 20),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showWeightDialog(context, weightProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Text(
                    weightProvider.weight < 1
                      ? '${(weightProvider.weight * 1000).toStringAsFixed(0)} g'
                      : '${weightProvider.weight.toStringAsFixed(weightProvider.weight < 10 ? 1 : 0)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeightDialog(BuildContext context, WeightProvider weightProvider) {
    double tempWeight = weightProvider.weight;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.monitor_weight, color: Colors.blue),
              SizedBox(width: 8),
              Text('Poids de l\'enfant'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tempWeight < 1 
                  ? '${(tempWeight * 1000).toStringAsFixed(0)} g'
                  : '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                    ),
                    child: Slider(
                      value: weightProvider.weightToSliderValue(tempWeight),
                      min: 0,
                      max: WeightProvider.totalPositions.toDouble(),
                      divisions: WeightProvider.totalPositions,
                      activeColor: Colors.blue.shade600,
                      onChanged: (val) {
                        setState(() {
                          tempWeight = weightProvider.sliderValueToWeight(val);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('400 g', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
                        Text('4 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        Text('7 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text('10 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        Text('50 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                weightProvider.setWeight(tempWeight);
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalWeightSelectorCompact extends StatelessWidget {
  const GlobalWeightSelectorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        return GestureDetector(
          onTap: () => _showWeightDialog(context, weightProvider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_weight, size: 18),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Text(
                  weightProvider.weight < 1
                    ? '${(weightProvider.weight * 1000).toStringAsFixed(0)} g'
                    : '${weightProvider.weight.toStringAsFixed(weightProvider.weight < 10 ? 1 : 0)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeightDialog(BuildContext context, WeightProvider weightProvider) {
    double tempWeight = weightProvider.weight;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.monitor_weight, color: Colors.blue),
              SizedBox(width: 8),
              Text('Poids de l\'enfant'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tempWeight < 1 
                  ? '${(tempWeight * 1000).toStringAsFixed(0)} g'
                  : '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                    ),
                    child: Slider(
                      value: weightProvider.weightToSliderValue(tempWeight),
                      min: 0,
                      max: WeightProvider.totalPositions.toDouble(),
                      divisions: WeightProvider.totalPositions,
                      activeColor: Colors.blue.shade600,
                      onChanged: (val) {
                        setState(() {
                          tempWeight = weightProvider.sliderValueToWeight(val);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('400 g', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
                        Text('4 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        Text('7 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text('10 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        Text('50 kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                weightProvider.setWeight(tempWeight);
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}