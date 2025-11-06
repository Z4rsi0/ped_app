import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Modèle simplifié de médicament
class Medicament {
  final String nom;
  final String galenique;
  final List<Indication> indications;
  final String? contreIndications;
  final String? surdosage;
  final String? aSavoir;

  Medicament({
    required this.nom,
    required this.galenique,
    required this.indications,
    this.contreIndications,
    this.surdosage,
    this.aSavoir,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      nom: json['nom'] ?? '',
      galenique: json['galenique'] ?? '',
      indications: (json['indications'] as List?)
          ?.map((i) => Indication.fromJson(i))
          .toList() ?? [],
      contreIndications: json['contreIndications'],
      surdosage: json['surdosage'],
      aSavoir: json['aSavoir'],
    );
  }
}

class Indication {
  final String label;
  final List<Posologie> posologies;

  Indication({required this.label, required this.posologies});

  factory Indication.fromJson(Map<String, dynamic> json) {
    return Indication(
      label: json['label'] ?? '',
      posologies: (json['posologies'] as List?)
          ?.map((p) => Posologie.fromJson(p))
          .toList() ?? [],
    );
  }
}

class Posologie {
  final String voie;
  final double doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final String unite;
  final String preparation;
  final double? doseMax;

  Posologie({
    required this.voie,
    required this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    required this.unite,
    required this.preparation,
    this.doseMax,
  });

  factory Posologie.fromJson(Map<String, dynamic> json) {
    return Posologie(
      voie: json['voie'] ?? '',
      doseKg: (json['doseKg'] ?? 0).toDouble(),
      doseKgMin: json['doseKgMin']?.toDouble(),
      doseKgMax: json['doseKgMax']?.toDouble(),
      unite: json['unite'] ?? '',
      preparation: json['preparation'] ?? '',
      doseMax: json['doseMax']?.toDouble(),
    );
  }

  String calculerDose(double poids) {
    if (doseKgMin != null && doseKgMax != null) {
      // Dose variable
      final doseMin = doseKgMin! * poids;
      final doseMax = doseKgMax! * poids;
      
      if (this.doseMax != null) {
        final doseMinFinal = doseMin > this.doseMax! ? this.doseMax! : doseMin;
        final doseMaxFinal = doseMax > this.doseMax! ? this.doseMax! : doseMax;
        return '${doseMinFinal.toStringAsFixed(1)} - ${doseMaxFinal.toStringAsFixed(1)} $unite\n(max ${this.doseMax} $unite)';
      }
      
      return '${doseMin.toStringAsFixed(1)} - ${doseMax.toStringAsFixed(1)} $unite';
    } else {
      // Dose fixe
      final dose = doseKg * poids;
      
      if (this.doseMax != null && dose > this.doseMax!) {
        return '${this.doseMax!.toStringAsFixed(1)} $unite (max atteint)';
      }
      
      return '${dose.toStringAsFixed(1)} $unite';
    }
  }
}

// Chargement des médicaments
Future<List<Medicament>> loadMedicaments() async {
  final data = await rootBundle.loadString('assets/medicaments_pediatrie.json');
  final List<dynamic> jsonList = json.decode(data);
  List<Medicament> meds = jsonList.map((json) => Medicament.fromJson(json)).toList();
  meds.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  return meds;
}

class TherapeutiqueScreen extends StatefulWidget {
  const TherapeutiqueScreen({super.key});

  @override
  State<TherapeutiqueScreen> createState() => _TherapeutiqueScreenState();
}

class _TherapeutiqueScreenState extends State<TherapeutiqueScreen> {
  double weight = 10.0;
  List<Medicament> medicaments = [];
  List<Medicament> filteredMedicaments = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await loadMedicaments();
      setState(() {
        medicaments = data;
        filteredMedicaments = medicaments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  void _filterMedicaments(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMedicaments = medicaments;
      } else {
        filteredMedicaments = medicaments
            .where((m) => m.nom.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thérapeutique Pédiatrique"),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          _buildWeightSlider(),
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMedicamentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_weight, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Poids:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Text(
                  '${weight.toStringAsFixed(weight < 10 ? 1 : 0)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              value: _weightToSliderValue(weight),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Colors.blue.shade600,
              onChanged: (val) {
                setState(() {
                  weight = _sliderValueToWeight(val);
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '10 kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '50 kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Conversion curseur → poids
  // 0-40: de 0 à 10 kg par pas de 0.1 kg (100 g)
  // 40-100: de 10 à 50 kg par pas de 1 kg
  double _sliderValueToWeight(double sliderValue) {
    if (sliderValue <= 40) {
      // 0 à 10 kg (par 100g)
      return sliderValue * 0.25; // 40 divisions pour 10 kg
    } else {
      // 10 à 50 kg (par kg)
      return 10 + (sliderValue - 40); // 60 divisions pour 40 kg
    }
  }

  // Conversion poids → curseur
  double _weightToSliderValue(double weight) {
    if (weight <= 10) {
      return weight / 0.25;
    } else {
      return 40 + (weight - 10);
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher un médicament",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _filterMedicaments('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _filterMedicaments,
      ),
    );
  }

  Widget _buildMedicamentsList() {
    if (filteredMedicaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun médicament trouvé',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMedicaments.length,
      itemBuilder: (context, index) {
        final med = filteredMedicaments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.medication, color: Colors.blue.shade700),
            ),
            title: Text(
              med.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              med.galenique,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicamentDetailScreen(
                  medicament: med,
                  initialWeight: weight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MedicamentDetailScreen extends StatefulWidget {
  final Medicament medicament;
  final double initialWeight;

  const MedicamentDetailScreen({
    super.key,
    required this.medicament,
    required this.initialWeight,
  });

  @override
  State<MedicamentDetailScreen> createState() => _MedicamentDetailScreenState();
}

class _MedicamentDetailScreenState extends State<MedicamentDetailScreen> {
  late double weight;

  @override
  void initState() {
    super.initState();
    weight = widget.initialWeight;
  }

  double _sliderValueToWeight(double sliderValue) {
    if (sliderValue <= 40) {
      return sliderValue * 0.25;
    } else {
      return 10 + (sliderValue - 40);
    }
  }

  double _weightToSliderValue(double weight) {
    if (weight <= 10) {
      return weight / 0.25;
    } else {
      return 40 + (weight - 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicament.nom),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          _buildWeightSlider(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      icon: Icons.medical_services,
                      title: "Galénique",
                      content: widget.medicament.galenique,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    ...widget.medicament.indications.map((indication) =>
                        _buildIndicationSection(indication)),
                    if (widget.medicament.contreIndications != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.warning,
                        title: "Contre-indications",
                        content: widget.medicament.contreIndications!,
                        color: Colors.red,
                      ),
                    ],
                    if (widget.medicament.surdosage != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.info,
                        title: "Surdosage",
                        content: widget.medicament.surdosage!,
                        color: Colors.orange,
                      ),
                    ],
                    if (widget.medicament.aSavoir != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.lightbulb,
                        title: "À savoir",
                        content: widget.medicament.aSavoir!,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_weight, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Poids:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Text(
                  '${weight.toStringAsFixed(weight < 10 ? 1 : 0)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              value: _weightToSliderValue(weight),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Colors.blue.shade600,
              onChanged: (val) {
                setState(() {
                  weight = _sliderValueToWeight(val);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildIndicationSection(Indication indication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  indication.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...indication.posologies.map((posologie) =>
              _buildPosologieCard(posologie)),
        ],
      ),
    );
  }

  Widget _buildPosologieCard(Posologie posologie) {
    final doseCalculee = posologie.calculerDose(weight);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  posologie.voie,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doseCalculee,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    posologie.preparation,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}