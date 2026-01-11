import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';
import '../widgets/global_weight_selector.dart';
import '../services/storage_service.dart';
import '../services/data_sync_service.dart';
import '../models/medication_model.dart';
import '../utils/string_utils.dart';
import '../theme/app_theme.dart';

class TherapeutiqueScreen extends StatefulWidget {
  const TherapeutiqueScreen({super.key});

  @override
  State<TherapeutiqueScreen> createState() => _TherapeutiqueScreenState();
}

class _TherapeutiqueScreenState extends State<TherapeutiqueScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = query);
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
    final medColors = context.medicalColors;
    
    return ValueListenableBuilder<Box<Medicament>>(
      valueListenable: _storage.medicamentListenable,
      builder: (context, box, _) {
        final allMeds = box.values.toList();
        
        List<Medicament> filteredList;
        if (_query.isEmpty) {
          filteredList = allMeds;
        } else {
          final scoredList = allMeds.map((med) {
            double scoreNom = StringUtils.similarity(_query, med.nom);
            double scoreComm = med.nomCommercial != null ? StringUtils.similarity(_query, med.nomCommercial!) : 0.0;
            return MapEntry(med, scoreNom > scoreComm ? scoreNom : scoreComm);
          }).toList();
          final relevant = scoredList.where((entry) => entry.value > 0.3).toList();
          relevant.sort((a, b) => b.value.compareTo(a.value));
          filteredList = relevant.map((entry) => entry.key).toList();
        }

        return Column(
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
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: filteredList.isEmpty
                    ? ListView(
                        children: [
                           SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                _query.isEmpty 
                                  ? (allMeds.isEmpty ? 'Chargement...' : 'Aucun médicament') 
                                  : 'Aucun résultat',
                                style: TextStyle(color: context.colors.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final med = filteredList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: medColors.medicamentContainer,
                                child: Icon(Icons.medication, color: medColors.medicamentOnContainer),
                              ),
                              title: Text(med.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (med.nomCommercial != null && med.nomCommercial!.isNotEmpty)
                                    Text(
                                      med.nomCommercial!,
                                      style: TextStyle(color: medColors.medicamentPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  Text(med.galenique, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MedicamentDetailScreen(medicament: med)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MedicamentDetailScreen extends StatelessWidget {
  final Medicament medicament;
  const MedicamentDetailScreen({super.key, required this.medicament});

  @override
  Widget build(BuildContext context) {
    final medColors = context.medicalColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
        backgroundColor: medColors.medicamentContainer,
        foregroundColor: medColors.medicamentOnContainer,
        // CORRECTION ICI : Utilisation de GlobalWeightSelector (version complète)
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8), 
            child: GlobalWeightSelector(), 
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medicament.nomCommercial != null)
              _buildSection(context, icon: Icons.local_pharmacy, title: "Nom commercial", content: medicament.nomCommercial!, color: medColors.medicamentPrimary, bgColor: medColors.medicamentContainer),
            if (medicament.nomCommercial != null) const SizedBox(height: 16),
            
            _buildSection(context, icon: Icons.medical_services, title: "Galénique", content: medicament.galenique, color: medColors.medicamentPrimary, bgColor: medColors.medicamentContainer),
            const SizedBox(height: 16),
            
            ...medicament.indications.map((indication) => IndicationCard(indication: indication)),
            
            if (medicament.contreIndications != null) ...[
              const SizedBox(height: 16),
              _buildSection(context, icon: Icons.warning, title: "Contre-indications", content: medicament.contreIndications!, color: medColors.alertePrimary, bgColor: medColors.alerteContainer),
            ],
            if (medicament.aSavoir != null) ...[
              const SizedBox(height: 16),
              _buildSection(context, icon: Icons.lightbulb, title: "À savoir", content: medicament.aSavoir!, color: medColors.annuairePrimary, bgColor: medColors.annuaireContainer),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String content, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: context.colors.onSurface)),
        ],
      ),
    );
  }
}

class IndicationCard extends StatefulWidget {
  final Indication indication;
  const IndicationCard({super.key, required this.indication});

  @override
  State<IndicationCard> createState() => _IndicationCardState();
}

class _IndicationCardState extends State<IndicationCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.medicalColors;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.annuaireContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.annuairePrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.local_hospital, color: colors.annuairePrimary, size: 20),
            title: Text(widget.indication.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.annuairePrimary)),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: colors.annuairePrimary),
            onTap: () => setState(() => isExpanded = !isExpanded),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: widget.indication.posologies.map((p) => _buildPosologieCard(context, p)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildPosologieCard(BuildContext context, Posologie posologie) {
    final calcColors = context.medicalColors;
    
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        final poids = weightProvider.weight ?? 10.0;
        final doseCalculee = posologie.calculerDose(poids);
        String doseParKg = '';
        if (posologie.doseKg != null) doseParKg = '(${posologie.doseKg} ${posologie.getUniteReference()})';

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.colors.outlineVariant)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: calcColors.medicamentContainer, borderRadius: BorderRadius.circular(4)),
                child: Text(posologie.voie, style: TextStyle(fontWeight: FontWeight.bold, color: calcColors.medicamentOnContainer)),
              ),
              const SizedBox(height: 12),
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(doseCalculee, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: calcColors.calculusOnContainer)),
                        if (doseParKg.isNotEmpty) Text(doseParKg, style: TextStyle(fontSize: 13, color: calcColors.calculusOnContainer.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                      ]),
                    ),
                  ],
                ),
              ),
              if (posologie.preparation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.science, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(posologie.preparation, style: TextStyle(fontStyle: FontStyle.italic, color: context.colors.onSurface))),
                ]),
              ]
            ],
          ),
        );
      },
    );
  }
}