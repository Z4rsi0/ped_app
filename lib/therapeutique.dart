// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weight_provider.dart';
import 'widgets/global_weight_selector.dart';
import 'services/data_sync_service.dart';
import 'models/medication_model.dart'; // Import du modèle unifié

// Fonction de parsing isolée (doit être top-level pour compute si besoin, 
// mais ici on passe une lambda à DataSyncService.readAndParseJson)
List<Medicament> _parseMedicamentsList(dynamic jsonList) {
  if (jsonList is List) {
    final list = jsonList.map((json) => Medicament.fromJson(json)).toList();
    // Tri alphabétique
    list.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    return list;
  }
  return [];
}

class TherapeutiqueScreen extends StatefulWidget {
  const TherapeutiqueScreen({super.key});

  @override
  State<TherapeutiqueScreen> createState() => _TherapeutiqueScreenState();
}

class _TherapeutiqueScreenState extends State<TherapeutiqueScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Medicament> medicaments = [];
  List<Medicament> filteredMedicaments = [];
  final searchController = TextEditingController();
  bool isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Utilisation du parsing optimisé (Isolate)
      final data = await DataSyncService.readAndParseJson(
        'medicaments_pediatrie.json',
        _parseMedicamentsList,
      );
      
      if (mounted) {
        setState(() {
          medicaments = data;
          filteredMedicaments = medicaments;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Impossible de charger les médicaments'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMedicaments(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            filteredMedicaments = medicaments;
          } else {
            final lowerQuery = query.toLowerCase();
            filteredMedicaments = medicaments
                .where((m) => m.nom.toLowerCase().contains(lowerQuery) ||
                             (m.nomCommercial?.toLowerCase().contains(lowerQuery) ?? false))
                .toList();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
          key: ValueKey(med.nom),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (med.nomCommercial != null && med.nomCommercial!.isNotEmpty)
                  Text(
                    med.nomCommercial!,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  med.galenique,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
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
              if (medicament.nomCommercial != null && medicament.nomCommercial!.isNotEmpty)
                _buildSection(
                  icon: Icons.local_pharmacy,
                  title: "Nom commercial",
                  content: medicament.nomCommercial!,
                  color: Colors.blue,
                ),
              if (medicament.nomCommercial != null)
                const SizedBox(height: 16),
              _buildSection(
                icon: Icons.medical_services,
                title: "Galénique",
                content: medicament.galenique,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              ...medicament.indications.map((indication) =>
                  _buildIndicationSection(context, indication)),
              if (medicament.contreIndications != null && medicament.contreIndications!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.warning,
                  title: "Contre-indications",
                  content: medicament.contreIndications!,
                  color: Colors.red,
                ),
              ],
              if (medicament.surdosage != null && medicament.surdosage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.info,
                  title: "Surdosage",
                  content: medicament.surdosage!,
                  color: Colors.orange,
                ),
              ],
              if (medicament.aSavoir != null && medicament.aSavoir!.isNotEmpty) ...[
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
    return Card( // Utilisation de Card pour cohérence visuelle
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.green.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
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
        final poids = weightProvider.weight ?? 10.0;
        // UTILISATION DE LA LOGIQUE DÉPLACÉE DANS LE MODÈLE
        final doseCalculee = posologie.calculerDose(poids);
        
        // Affichage de la posologie de référence
        String doseParKg = '';
        final uniteRef = posologie.getUniteReference();
        
        if (posologie.doses != null && posologie.doses!.isNotEmpty) {
           // Schéma complexe : on n'affiche pas de "dose/kg" simple
        } else if (posologie.doseKg != null) {
          doseParKg = '(${posologie.doseKg} $uniteRef)';
        } else if (posologie.doseKgMin != null && posologie.doseKgMax != null) {
          doseParKg = '(${posologie.doseKgMin} - ${posologie.doseKgMax} $uniteRef)';
        }
        
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doseCalculee,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          if (doseParKg.isNotEmpty)
                            Text(
                              doseParKg,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (posologie.preparation.isNotEmpty) ...[
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
              ]
            ],
          ),
        );
      },
    );
  }
}