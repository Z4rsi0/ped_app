// ignore_for_file: unnecessary_null_comparison, dead_code, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weight_provider.dart';
import 'main.dart';
import 'services/data_sync_service.dart';

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

class TranchePosologie {
  final double? poidsMin;
  final double? poidsMax;
  final double? doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final String? doses; // Pour les schémas complexes comme "S0: 80 mg, S2: 40 mg..."

  TranchePosologie({
    this.poidsMin,
    this.poidsMax,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.doses,
  });

  factory TranchePosologie.fromJson(Map<String, dynamic> json) {
    return TranchePosologie(
      poidsMin: _parseDouble(json['poidsMin']),
      poidsMax: _parseDouble(json['poidsMax']),
      doseKg: _parseDouble(json['doseKg']),
      doseKgMin: _parseDouble(json['doseKgMin']),
      doseKgMax: _parseDouble(json['doseKgMax']),
      doses: json['doses']?.toString(),
    );
  }

  bool appliqueAPoids(double poids) {
    if (poidsMin != null && poids < poidsMin!) return false;
    if (poidsMax != null && poids > poidsMax!) return false;
    return true;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

class Posologie {
  final String voie;
  final double? doseKg;
  final double? doseKgMin;
  final double? doseKgMax;
  final List<TranchePosologie>? tranches;
  final String unite;
  final String preparation;
  final dynamic doseMax; // peut être String ou double

  Posologie({
    required this.voie,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.tranches,
    required this.unite,
    required this.preparation,
    this.doseMax,
  });

  factory Posologie.fromJson(Map<String, dynamic> json) {
    return Posologie(
      voie: json['voie'] ?? '',
      doseKg: _parseDouble(json['doseKg']),
      doseKgMin: _parseDouble(json['doseKgMin']),
      doseKgMax: _parseDouble(json['doseKgMax']),
      tranches: (json['tranches'] as List?)
          ?.map((t) => TranchePosologie.fromJson(t))
          .toList(),
      unite: json['unite'] ?? '',
      preparation: json['preparation'] ?? '',
      doseMax: json['doseMax'], // Garder tel quel
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String calculerDose(double poids) {
    // Si tranches de poids définies
    if (tranches != null && tranches!.isNotEmpty) {
      final tranche = tranches!.firstWhere(
        (t) => t.appliqueAPoids(poids),
        orElse: () => tranches!.first,
      );
      
      // Si la tranche contient un schéma de doses textuelles
      if (tranche.doses != null) {
        return tranche.doses!;
      }
      
      if (tranche.doseKgMin != null && tranche.doseKgMax != null) {
        final doseMin = tranche.doseKgMin! * poids;
        final doseMax = tranche.doseKgMax! * poids;
        return _formatDoseAvecUnite(doseMin, doseMax, unite);
      } else if (tranche.doseKg != null) {
        final dose = tranche.doseKg! * poids;
        return _formatDoseAvecUnite(dose, null, unite);
      }
    }
    
    // Sinon, dose variable globale
    if (doseKgMin != null && doseKgMax != null) {
      final doseMin = doseKgMin! * poids;
      final doseMax = doseKgMax! * poids;
      
      // Gestion de la dose max
      double? doseMaxDouble = _parseDouble(doseMax);
      if (doseMaxDouble != null) {
        final doseMinFinal = doseMin > doseMaxDouble ? doseMaxDouble : doseMin;
        final doseMaxFinal = doseMax > doseMaxDouble ? doseMaxDouble : doseMax;
        return '${_formatDoseAvecUnite(doseMinFinal, doseMaxFinal, unite)}\n(max ${_formatDoseMaximale(doseMax)})';
      }
      
      return _formatDoseAvecUnite(doseMin, doseMax, unite);
    } else if (doseKg != null) {
      // Dose fixe
      final dose = doseKg! * poids;
      
      double? doseMaxDouble = _parseDouble(doseMax);
      if (doseMaxDouble != null && dose > doseMaxDouble) {
        return '${_formatDoseAvecUnite(doseMaxDouble, null, unite)} (max atteint)';
      }
      
      return _formatDoseAvecUnite(dose, null, unite);
    }
    
    return "Dose non calculable";
  }

  String _formatDoseMaximale(dynamic doseMax) {
    if (doseMax == null) return '';
    if (doseMax is String) return doseMax;
    if (doseMax is num) return '${doseMax.toStringAsFixed(0)} $unite';
    return doseMax.toString();
  }

  String _formatDoseAvecUnite(double dose1, double? dose2, String uniteOriginale) {
    // Conversion mg <-> µg
    if (uniteOriginale == 'mg') {
      if (dose1 < 0.1) {
        // Convertir en µg
        if (dose2 != null) {
          return '${(dose1 * 1000).toStringAsFixed(0)} - ${(dose2 * 1000).toStringAsFixed(0)} µg';
        }
        return '${(dose1 * 1000).toStringAsFixed(0)} µg';
      }
    } else if (uniteOriginale == 'µg') {
      if (dose1 > 999) {
        // Convertir en mg
        if (dose2 != null) {
          return '${(dose1 / 1000).toStringAsFixed(1)} - ${(dose2 / 1000).toStringAsFixed(1)} mg';
        }
        return '${(dose1 / 1000).toStringAsFixed(1)} mg';
      }
    }
    
    // Format normal
    if (dose2 != null) {
      return '${dose1.toStringAsFixed(1)} - ${dose2.toStringAsFixed(1)} $uniteOriginale';
    }
    return '${dose1.toStringAsFixed(1)} $uniteOriginale';
  }
}

// Chargement des médicaments
Future<List<Medicament>> loadMedicaments() async {
  final data = await DataSyncService.readFile('medicaments_pediatrie.json');
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
      body: Column(
        children: [
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
                builder: (_) => MedicamentDetailScreen(medicament: med),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MedicamentDetailScreen extends StatelessWidget {
  final Medicament medicament;

  const MedicamentDetailScreen({
    super.key,
    required this.medicament,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
        backgroundColor: Colors.blue.shade100,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: GlobalWeightSelectorCompact(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                icon: Icons.medical_services,
                title: "Galénique",
                content: medicament.galenique,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              ...medicament.indications.map((indication) =>
                  _buildIndicationSection(context, indication)),
              if (medicament.contreIndications != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.warning,
                  title: "Contre-indications",
                  content: medicament.contreIndications!,
                  color: Colors.red,
                ),
              ],
              if (medicament.surdosage != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.info,
                  title: "Surdosage",
                  content: medicament.surdosage!,
                  color: Colors.orange,
                ),
              ],
              if (medicament.aSavoir != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.lightbulb,
                  title: "À savoir",
                  content: medicament.aSavoir!,
                  color: Colors.green,
                ),
              ],
            ],
          ),
        ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildIndicationSection(BuildContext context, Indication indication) {
    return IndicationCard(indication: indication);
  }
}

class IndicationCard extends StatefulWidget {
  final Indication indication;

  const IndicationCard({
    super.key,
    required this.indication,
  });

  @override
  State<IndicationCard> createState() => _IndicationCardState();
}

class _IndicationCardState extends State<IndicationCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.green, size: 20),
            title: Text(
              widget.indication.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.green,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: widget.indication.posologies.map((posologie) =>
                    _buildPosologieCard(context, posologie)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPosologieCard(BuildContext context, Posologie posologie) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        final doseCalculee = posologie.calculerDose(weightProvider.weight);
        
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
      },
    );
  }
}