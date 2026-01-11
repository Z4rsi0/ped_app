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
  Widget build(BuildContext context) {
    final medColors = context.medicalColors;
    
    // 🔥 REACTIVITÉ HIVE
    return ValueListenableBuilder<Box<Medicament>>(
      valueListenable: _storage.medicamentListenable,
      builder: (context, box, _) {
        final allMeds = box.values.toList();
        
        // Filtrage
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
                  prefixIcon: const Icon(Icons.search),
                  fillColor: context.colors.surfaceContainerHigh,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() => _query = ''); }) : null,
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
                                _query.isEmpty ? (allMeds.isEmpty ? 'Chargement...' : 'Aucun médicament') : 'Aucun résultat',
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
                              subtitle: med.nomCommercial != null ? Text(med.nomCommercial!, style: TextStyle(color: medColors.medicamentPrimary, fontSize: 11)) : null,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicamentDetailScreen(medicament: med))),
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

// Détail Medicament (Inclus ici pour simplifier le copier-coller, mais idéalement dans son propre fichier)
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
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: Center(child: GlobalWeightSelectorCompact()))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (medicament.nomCommercial != null) _InfoBlock(title: "Commercial", content: medicament.nomCommercial!, color: medColors.medicamentPrimary),
            const SizedBox(height: 12),
            _InfoBlock(title: "Galénique", content: medicament.galenique, color: medColors.medicamentPrimary),
            const SizedBox(height: 12),
            ...medicament.indications.map((i) => IndicationCard(indication: i)),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  const _InfoBlock({required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text(content),
      ]),
    );
  }
}

// IndicationCard est supposé être connu ou importé. Si manquant, il faut le rajouter ici.
// Je le rajoute pour être sûr que le code compile.
class IndicationCard extends StatefulWidget {
  final Indication indication;
  const IndicationCard({super.key, required this.indication});
  @override
  State<IndicationCard> createState() => _IndicationCardState();
}
class _IndicationCardState extends State<IndicationCard> {
  bool isExpanded = true;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(widget.indication.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: widget.indication.posologies.map((p) => _PosoTile(posologie: p)).toList(),
      ),
    );
  }
}

class _PosoTile extends StatelessWidget {
  final Posologie posologie;
  const _PosoTile({required this.posologie});
  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, wp, _) {
        final dose = posologie.calculerDose(wp.weight ?? 10.0);
        return ListTile(
          title: Text(dose, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
          subtitle: Text('${posologie.voie} - ${posologie.preparation}'),
        );
      }
    );
  }
}