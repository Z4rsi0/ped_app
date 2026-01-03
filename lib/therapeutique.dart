// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weight_provider.dart';
import 'widgets/global_weight_selector.dart';
import 'services/data_sync_service.dart';
import 'models/medication_model.dart';
import 'utils/string_utils.dart';
import 'theme/app_theme.dart'; // Import du Design System

// Fonction de parsing isolée
List<Medicament> _parseMedicamentsList(dynamic jsonList) {
  if (jsonList is List) {
    final list = jsonList.map((json) => Medicament.fromJson(json)).toList();
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

class _TherapeutiqueScreenState extends State<TherapeutiqueScreen>
    with AutomaticKeepAliveClientMixin {
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
          const SnackBar(
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
      if (!mounted) return;

      setState(() {
        if (query.isEmpty) {
          filteredMedicaments = medicaments;
        } else {
          final scoredList = medicaments.map((med) {
            double scoreNom = StringUtils.similarity(query, med.nom);
            double scoreComm = 0.0;
            if (med.nomCommercial != null) {
              scoreComm = StringUtils.similarity(query, med.nomCommercial!);
            }
            return MapEntry(med, scoreNom > scoreComm ? scoreNom : scoreComm);
          }).toList();

          final relevant =
              scoredList.where((entry) => entry.value > 0.3).toList();
          relevant.sort((a, b) => b.value.compareTo(a.value));

          filteredMedicaments = relevant.map((entry) => entry.key).toList();
        }
      });
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
    final medColors = context.medicalColors;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un médicament",
                prefixIcon: Icon(Icons.search, color: context.colors.onSurfaceVariant),
                fillColor: context.colors.surfaceContainerHigh,
                filled: true,
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
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterMedicaments,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMedicamentsList(medColors),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentsList(MedicalColors medColors) {
    if (filteredMedicaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.colors.outline),
            const SizedBox(height: 16),
            Text(
              'Aucun médicament trouvé',
              style: context.textTheme.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: medColors.medicamentContainer,
              child: Icon(Icons.medication, color: medColors.medicamentOnContainer),
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
                      color: medColors.medicamentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  med.galenique,
                  style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
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
    final medColors = context.medicalColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
        backgroundColor: medColors.medicamentContainer,
        foregroundColor: medColors.medicamentOnContainer,
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
              if (medicament.nomCommercial != null &&
                  medicament.nomCommercial!.isNotEmpty)
                _buildSection(
                  context,
                  icon: Icons.local_pharmacy,
                  title: "Nom commercial",
                  content: medicament.nomCommercial!,
                  color: medColors.medicamentPrimary,
                  bgColor: medColors.medicamentContainer,
                ),
              if (medicament.nomCommercial != null)
                const SizedBox(height: 16),
              _buildSection(
                context,
                icon: Icons.medical_services,
                title: "Galénique",
                content: medicament.galenique,
                color: medColors.medicamentPrimary,
                bgColor: medColors.medicamentContainer,
              ),
              const SizedBox(height: 16),
              ...medicament.indications.map((indication) =>
                  _buildIndicationSection(context, indication)),
              
              if (medicament.contreIndications != null &&
                  medicament.contreIndications!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.warning,
                  title: "Contre-indications",
                  content: medicament.contreIndications!,
                  color: medColors.alertePrimary,
                  bgColor: medColors.alerteContainer,
                ),
              ],
              if (medicament.surdosage != null &&
                  medicament.surdosage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.info,
                  title: "Surdosage",
                  content: medicament.surdosage!,
                  color: medColors.protocolPrimary, // Orange pour attention
                  bgColor: medColors.protocolContainer,
                ),
              ],
              if (medicament.aSavoir != null &&
                  medicament.aSavoir!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.lightbulb,
                  title: "À savoir",
                  content: medicament.aSavoir!,
                  color: medColors.annuairePrimary, // Vert pour info
                  bgColor: medColors.annuaireContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2), // Légère transparence pour le fond
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
          Text(
            content,
            style: TextStyle(color: context.colors.onSurface),
          ),
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
    final annuaireColors = context.medicalColors; // Vert sémantique
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: annuaireColors.annuaireContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: annuaireColors.annuairePrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.local_hospital, color: annuaireColors.annuairePrimary, size: 20),
            title: Text(
              widget.indication.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: annuaireColors.annuairePrimary,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: annuaireColors.annuairePrimary,
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
                children: widget.indication.posologies
                    .map((posologie) => _buildPosologieCard(context, posologie))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPosologieCard(BuildContext context, Posologie posologie) {
    final calcColors = context.medicalColors; // Violet sémantique
    final surfaceColor = context.colors.surface;

    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        final poids = weightProvider.weight ?? 10.0;
        final doseCalculee = posologie.calculerDose(poids);

        String doseParKg = '';
        final uniteRef = posologie.getUniteReference();

        if (posologie.doses != null && posologie.doses!.isNotEmpty) {
           // Pas de dose/kg simple
        } else if (posologie.doseKg != null) {
          doseParKg = '(${posologie.doseKg} $uniteRef)';
        } else if (posologie.doseKgMin != null && posologie.doseKgMax != null) {
          doseParKg = '(${posologie.doseKgMin} - ${posologie.doseKgMax} $uniteRef)';
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voie d'administration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: calcColors.medicamentContainer, // Rappel bleu médicament
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  posologie.voie,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: calcColors.medicamentOnContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Zone de calcul (Violet)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: calcColors.calculusContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: calcColors.calculusPrimary.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate, color: calcColors.calculusPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doseCalculee,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: calcColors.calculusOnContainer, // Contraste assuré
                            ),
                          ),
                          if (doseParKg.isNotEmpty)
                            Text(
                              doseParKg,
                              style: TextStyle(
                                fontSize: 13,
                                color: calcColors.calculusOnContainer.withValues(alpha: 0.7),
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
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science, size: 16, color: context.colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          posologie.preparation,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: context.colors.onSurface,
                          ),
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