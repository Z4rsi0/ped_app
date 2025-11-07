import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/medicament_resolver.dart';
import 'providers/weight_provider.dart';
import 'main.dart';
import 'services/data_sync_service.dart';

class Protocole {
  final String nom;
  final String description;
  final List<Etape> etapes;

  Protocole({
    required this.nom,
    required this.description,
    required this.etapes,
  });

  factory Protocole.fromJson(Map<String, dynamic> json) {
    return Protocole(
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      etapes: (json['etapes'] as List?)
          ?.map((e) => Etape.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Etape {
  final String titre;
  final String? temps;
  final List<ElementEtape> elements;
  final String? attention;

  Etape({
    required this.titre,
    this.temps,
    required this.elements,
    this.attention,
  });

  factory Etape.fromJson(Map<String, dynamic> json) {
    return Etape(
      titre: json['titre'] ?? '',
      temps: json['temps'],
      elements: (json['elements'] as List?)
          ?.map((e) => ElementEtape.fromJson(e))
          .toList() ?? [],
      attention: json['attention'],
    );
  }
}

class ElementEtape {
  final String type; // "texte" ou "medicament"
  final String? texte;
  final ReferenceMedicament? medicament;

  ElementEtape({
    required this.type,
    this.texte,
    this.medicament,
  });

  factory ElementEtape.fromJson(Map<String, dynamic> json) {
    return ElementEtape(
      type: json['type'] ?? 'texte',
      texte: json['texte'],
      medicament: json['medicament'] != null
          ? ReferenceMedicament.fromJson(json['medicament'])
          : null,
    );
  }
}

class ReferenceMedicament {
  final String nomMedicament;
  final String indication;
  final String? voie;

  ReferenceMedicament({
    required this.nomMedicament,
    required this.indication,
    this.voie,
  });

  factory ReferenceMedicament.fromJson(Map<String, dynamic> json) {
    return ReferenceMedicament(
      nomMedicament: json['nom'] ?? '',
      indication: json['indication'] ?? '',
      voie: json['voie'],
    );
  }
}

/// Liste des protocoles disponibles
Future<List<String>> loadProtocolesList() async {
  return [
    'etat_de_mal_epileptique',
    'arret_cardio_respiratoire',
  ];
}

/// Charge un protocole depuis son nom de fichier
/// @param filename Nom du fichier sans extension, ex: 'etat_de_mal_epileptique'
Future<Protocole> loadProtocole(String filename) async {
  // Chemin complet avec préfixe assets/
  final data = await DataSyncService.readFile('assets/protocoles/$filename.json');
  final jsonData = json.decode(data);
  return Protocole.fromJson(jsonData);
}

class ProtocolesScreen extends StatefulWidget {
  const ProtocolesScreen({super.key});

  @override
  State<ProtocolesScreen> createState() => _ProtocolesScreenState();
}

class _ProtocolesScreenState extends State<ProtocolesScreen> {
  List<String> protocolesFiles = [];
  Map<String, Protocole> protocoles = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charger le resolver de médicaments
      await MedicamentResolver().loadMedicaments();
      
      final files = await loadProtocolesList();
      Map<String, Protocole> loadedProtocoles = {};
      
      for (String file in files) {
        try {
          final protocole = await loadProtocole(file);
          loadedProtocoles[file] = protocole;
          debugPrint('✅ Protocole chargé: $file');
        } catch (e) {
          debugPrint('❌ Erreur chargement protocole $file: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          protocolesFiles = files;
          protocoles = loadedProtocoles;
          isLoading = false;
          errorMessage = loadedProtocoles.isEmpty ? 'Aucun protocole chargé' : null;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur globale: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Protocoles"),
        backgroundColor: Colors.orange.shade100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : protocoles.isEmpty
                  ? _buildEmptyView()
                  : _buildProtocolesList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun protocole disponible',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: protocoles.length,
      itemBuilder: (context, index) {
        final file = protocolesFiles[index];
        final protocole = protocoles[file];
        
        if (protocole == null) return const SizedBox.shrink();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.description,
                  color: Colors.orange.shade700),
            ),
            title: Text(
              protocole.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              protocole.description,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProtocoleDetailScreen(protocole: protocole),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProtocoleDetailScreen extends StatelessWidget {
  final Protocole protocole;

  const ProtocoleDetailScreen({super.key, required this.protocole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(protocole.nom),
        backgroundColor: Colors.orange.shade100,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: GlobalWeightSelectorCompact(),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: protocole.etapes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    protocole.description,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            );
          }

          final etape = protocole.etapes[index - 1];
          return _buildEtapeCard(context, etape, index);
        },
      ),
    );
  }

  Widget _buildEtapeCard(BuildContext context, Etape etape, int numero) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    etape.titre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (etape.temps != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          etape.temps!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...etape.elements.map((element) => ElementEtapeWidget(element: element)),
                if (etape.attention != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            etape.attention!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ElementEtapeWidget extends StatelessWidget {
  final ElementEtape element;

  const ElementEtapeWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    if (element.type == 'texte') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          element.texte ?? '',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      );
    } else if (element.type == 'medicament' && element.medicament != null) {
      return MedicamentReferenceWidget(reference: element.medicament!);
    }
    return const SizedBox.shrink();
  }
}

class MedicamentReferenceWidget extends StatelessWidget {
  final ReferenceMedicament reference;

  const MedicamentReferenceWidget({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    final weightProvider = Provider.of<WeightProvider>(context);
    final resolver = MedicamentResolver();

    PosologieResolue? posologie;
    String? errorMessage;

    try {
      posologie = resolver.resolveMedicament(
        nomMedicament: reference.nomMedicament,
        indication: reference.indication,
        voie: reference.voie,
        poids: weightProvider.weight,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    if (errorMessage != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erreur: $errorMessage',
                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (posologie == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.medication, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      posologie.nomMedicament,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    Text(
                      posologie.voie,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, size: 16, color: Colors.purple.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Dose:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  posologie.dose,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            posologie.preparation,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}