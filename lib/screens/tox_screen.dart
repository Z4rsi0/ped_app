import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/toxic_agent.dart';
import '../models/medication_model.dart';
import '../services/toxicology_service.dart';
import '../services/storage_service.dart';
import '../providers/weight_provider.dart';
import '../logic/toxicology_logic.dart';
import '../utils/string_utils.dart';

class ToxScreen extends StatefulWidget {
  const ToxScreen({super.key});

  @override
  State<ToxScreen> createState() => _ToxScreenState();
}

class _ToxScreenState extends State<ToxScreen> {
  final ToxicologyService _toxService = ToxicologyService();
  final TextEditingController _doseController = TextEditingController();
  
  ToxicAgent? _selectedAgent;
  bool _isDoseUnknown = false;
  
  @override
  void initState() {
    super.initState();
    _doseController.addListener(() {
      setState(() {}); 
    });
  }
  
  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  // --- CORRECTION ICI ---
  void _onAgentSelected(ToxicAgent agent) {
    setState(() {
      _selectedAgent = agent;
      _doseController.clear(); // On efface l'ancienne dose
      _isDoseUnknown = false;  // On réactive le champ de saisie
    });
  }
  // ----------------------

  @override
  Widget build(BuildContext context) {
    final double weight = context.watch<WeightProvider>().weight ?? 0.0;
    
    final doseText = _doseController.text.replaceAll(',', '.');
    final double doseInput = double.tryParse(doseText) ?? 0.0;

    ToxicityResult? result;
    if (_selectedAgent != null) {
      result = ToxicologyLogic.evaluateRisk(
        agent: _selectedAgent!,
        ingestedDose: doseInput,
        patientWeight: weight,
        isDoseUnknown: _isDoseUnknown,
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  
                  const SizedBox(height: 24),

                  if (_selectedAgent != null) ...[
                    _buildDoseInputCard(weight),
                    const SizedBox(height: 24),
                    if (result != null) _buildResultBlock(result, weight),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                ],
              ),
            ),
          ),
          
          _buildDisclaimer(),
        ],
      ),
    );
  }

  // --- WIDGETS D'INTERFACE ---

  Widget _buildSearchField() {
    return Autocomplete<ToxicAgent>(
      displayStringForOption: (agent) => agent.nom,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _toxService.searchAgents(textEditingValue.text);
      },
      onSelected: _onAgentSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Rechercher un toxique',
            hintText: 'Ex: Paracétamol, Advil...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ToxicAgent option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: option.motsCles.isNotEmpty 
                        ? Text(option.motsCles.join(", "), maxLines: 1, overflow: TextOverflow.ellipsis) 
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoseInputCard(double currentWeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final agent = _selectedAgent!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    agent.nom,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _doseController,
                    enabled: !_isDoseUnknown,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Dose ingérée',
                      hintText: '0',
                      suffixText: agent.unite.split('/').first,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: _isDoseUnknown ? Colors.grey.shade100 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Icon(Icons.monitor_weight_outlined, color: Colors.grey),
                    Text("${currentWeight.toStringAsFixed(1)} kg", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            
            InkWell(
              onTap: () {
                setState(() {
                  _isDoseUnknown = !_isDoseUnknown;
                  if (_isDoseUnknown) _doseController.clear();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isDoseUnknown,
                      onChanged: (val) {
                        setState(() {
                          _isDoseUnknown = val ?? false;
                          if (_isDoseUnknown) _doseController.clear();
                        });
                      },
                    ),
                    Text(
                      "Dose ingérée inconnue",
                      style: TextStyle(
                        color: _isDoseUnknown ? colorScheme.error : null,
                        fontWeight: _isDoseUnknown ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBlock(ToxicityResult result, double weight) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;

    switch (result.status) {
      case ToxicityStatus.safe:
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;
        title = "DOSE NON TOXIQUE";
        break;
      case ToxicityStatus.uncertain:
        cardColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        title = "RISQUE INCERTAIN";
        break;
      case ToxicityStatus.toxic:
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.gpp_maybe_rounded;
        title = "DOSE TOXIQUE";
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_isDoseUnknown)
                Text(
                  "Dose reçue : ${result.calculatedDose.toStringAsFixed(1)} ${result.unit}",
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              const SizedBox(height: 4),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (result.status != ToxicityStatus.safe) ...[
          _buildInfoCard("Conduite à tenir", result.agent.conduiteATenir, Icons.medical_services_outlined),
          
          if (result.agent.picCinetique != null)
            _buildInfoCard("Pic d'absorption", result.agent.picCinetique!, Icons.access_time),
            
          if (result.agent.demiVie != null)
            _buildInfoCard("Demi-vie", result.agent.demiVie!, Icons.timelapse),

          if (result.agent.antidoteId != null)
             _buildAntidoteCard(result.agent.antidoteId!, weight),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }

  Widget _buildAntidoteCard(String antidoteId, double weight) {
    final meds = StorageService().getMedicaments();
    Medicament? antidote;
    
    final normalizedId = StringUtils.normalize(antidoteId);
    
    try {
      antidote = meds.firstWhere((m) {
        final normalizedName = StringUtils.normalize(m.nom);
        return normalizedName.contains(normalizedId) || normalizedId.contains(normalizedName);
      });
    } catch (e) {
      // Pas trouvé
    }

    if (antidote == null) return const SizedBox();

    // FILTRAGE INTELLIGENT
    final toxIndications = antidote.indications.where((indication) {
      final label = StringUtils.normalize(indication.label);
      return label.contains('intox') || 
             label.contains('antidote') || 
             label.contains('surdosage');
    }).toList();

    final indicationsToShow = toxIndications.isNotEmpty ? toxIndications : [];

    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: Colors.purple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Antidote : ${antidote.nom}",
                    style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const Divider(),
            
            if (indicationsToShow.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("Voir la fiche complète du médicament pour les posologies.", style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ...indicationsToShow.map((indication) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          indication.label,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      ...indication.posologies.map((poso) {
                        String dosageDisplay = "";
                        try {
                          dosageDisplay = poso.calculerDose(weight);
                        } catch (e) {
                          if (poso.doseKg != null) {
                             final total = (poso.doseKg! * weight).round();
                             dosageDisplay = "$total ${poso.unite} (${poso.doseKg} ${poso.unite}/kg)";
                          } else {
                             dosageDisplay = poso.doses ?? "";
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, height: 1.5)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dosageDisplay.isNotEmpty)
                                      Text(
                                        "${poso.voie}: $dosageDisplay", 
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                                      ),
                                    
                                    if (poso.preparation.isNotEmpty)
                                       Text(
                                         "Préparation : ${poso.preparation}", 
                                         style: TextStyle(fontStyle: FontStyle.italic, color: Colors.purple.shade800, fontSize: 13)
                                       ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.medication_liquid_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Recherchez un toxique pour évaluer le risque.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              "Aide au calcul. Ne remplace pas l'avis du CAP.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}