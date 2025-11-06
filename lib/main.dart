import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'therapeutique.dart';
import 'annuaire.dart';
import 'protocoles.dart';
import 'providers/weight_provider.dart';

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
      appBar: AppBar(
        title: const Text('Thérapeutique Pédiatrique'),
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
                    '${weightProvider.weight.toStringAsFixed(weightProvider.weight < 10 ? 1 : 0)} kg',
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
                '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                ),
                child: Slider(
                  value: weightProvider.weightToSliderValue(tempWeight),
                  min: 0,
                  max: 90,
                  divisions: 90,
                  activeColor: Colors.blue.shade600,
                  onChanged: (val) {
                    setState(() {
                      tempWeight = weightProvider.sliderValueToWeight(val);
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 kg', style: TextStyle(color: Colors.grey.shade600)),
                  Text('10 kg', style: TextStyle(color: Colors.grey.shade600)),
                  Text('50 kg', style: TextStyle(color: Colors.grey.shade600)),
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
                  '${weightProvider.weight.toStringAsFixed(weightProvider.weight < 10 ? 1 : 0)} kg',
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
                '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                ),
                child: Slider(
                  value: weightProvider.weightToSliderValue(tempWeight),
                  min: 0,
                  max: 90,
                  divisions: 90,
                  activeColor: Colors.blue.shade600,
                  onChanged: (val) {
                    setState(() {
                      tempWeight = weightProvider.sliderValueToWeight(val);
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 kg', style: TextStyle(color: Colors.grey.shade600)),
                  Text('10 kg', style: TextStyle(color: Colors.grey.shade600)),
                  Text('50 kg', style: TextStyle(color: Colors.grey.shade600)),
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