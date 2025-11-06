import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  final String contenu;
  final String? attention;

  Etape({
    required this.titre,
    this.temps,
    required this.contenu,
    this.attention,
  });

  factory Etape.fromJson(Map<String, dynamic> json) {
    return Etape(
      titre: json['titre'] ?? '',
      temps: json['temps'],
      contenu: json['contenu'] ?? '',
      attention: json['attention'],
    );
  }
}

Future<List<String>> loadProtocolesList() async {
  // Liste des fichiers de protocoles disponibles
  return [
    'etat_de_mal_epileptique',
    'arret_cardio_respiratoire',
  ];
}

Future<Protocole> loadProtocole(String filename) async {
  final data = await rootBundle.loadString('assets/protocoles/$filename.json');
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final files = await loadProtocolesList();
      Map<String, Protocole> loadedProtocoles = {};
      
      for (String file in files) {
        try {
          final protocole = await loadProtocole(file);
          loadedProtocoles[file] = protocole;
        } catch (e) {
          print('Erreur chargement $file: $e');
        }
      }
      
      setState(() {
        protocolesFiles = files;
        protocoles = loadedProtocoles;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Protocoles"),
        backgroundColor: Colors.orange.shade100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : protocoles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun protocole disponible',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                ),
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
          return _buildEtapeCard(etape, index);
        },
      ),
    );
  }

  Widget _buildEtapeCard(Etape etape, int numero) {
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
                  decoration: BoxDecoration(
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
                Text(
                  etape.contenu,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
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