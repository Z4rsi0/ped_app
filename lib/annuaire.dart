import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/annuaire_model.dart';
import 'services/data_sync_service.dart';

// Parser isolé pour l'annuaire (utilisé par le compute)
Annuaire _parseAnnuaire(dynamic jsonMap) {
  return Annuaire.fromJson(jsonMap as Map<String, dynamic>);
}

class AnnuaireScreen extends StatefulWidget {
  const AnnuaireScreen({super.key});

  @override
  State<AnnuaireScreen> createState() => _AnnuaireScreenState();
}

class _AnnuaireScreenState extends State<AnnuaireScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool isInterne = true;
  Annuaire? annuaire;
  bool isLoading = true;
  final searchController = TextEditingController();
  List<Service> filteredServices = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Chargement optimisé via Isolate pour ne pas bloquer l'UI
      final data = await DataSyncService.readAndParseJson(
        'annuaire.json',
        _parseAnnuaire,
      );
      
      if (mounted) {
        setState(() {
          annuaire = data;
          _updateFilteredServices();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur annuaire: $e')),
        );
      }
    }
  }

  void _updateFilteredServices() {
    if (annuaire == null) return;
    List<Service> services = isInterne ? annuaire!.interne : annuaire!.externe;

    if (searchController.text.isEmpty) {
      filteredServices = services;
    } else {
      final query = searchController.text.toLowerCase();
      filteredServices = services.where((s) {
        // Recherche sur le nom du service
        if (s.nom.toLowerCase().contains(query)) return true;
        // Recherche sur la description
        if (s.description?.toLowerCase().contains(query) ?? false) return true;
        // Recherche sur les contacts (numéro ou label)
        for (var contact in s.contacts) {
          if (contact.label?.toLowerCase().contains(query) ?? false) return true;
          if (contact.numero.contains(query)) return true;
        }
        return false;
      }).toList();
    }
  }

  void _filterServices(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _updateFilteredServices());
    });
  }

  void _toggleMode(bool interne) {
    setState(() {
      isInterne = interne;
      _updateFilteredServices();
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
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuaire"),
        backgroundColor: Colors.green.shade100,
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      color: Colors.green.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildModeButton('Interne', isInterne, Icons.business, () => _toggleMode(true))),
          const SizedBox(width: 12),
          Expanded(child: _buildModeButton('Externe', !isInterne, Icons.public, () => _toggleMode(false))),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isActive, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green.shade600 : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher un service ou contact",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _filterServices('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: _filterServices,
      ),
    );
  }

  Widget _buildServicesList() {
    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucun service trouvé', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        return ServiceCard(
          key: ValueKey(filteredServices[index].nom),
          service: filteredServices[index],
        );
      },
    );
  }
}

class ServiceCard extends StatefulWidget {
  final Service service;

  const ServiceCard({super.key, required this.service});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Utilisation de RepaintBoundary pour optimiser le rendu lors du scroll
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.phone_in_talk, color: Colors.green.shade700),
              ),
              title: Text(
                widget.service.nom,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: widget.service.description != null
                  ? Text(widget.service.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                  : null,
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.green.shade700,
              ),
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: widget.service.contacts.map((contact) {
                    return ContactTile(
                      key: ValueKey(contact.numero),
                      contact: contact,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

  /// Détermine si un numéro est cliquable (appelable)
  /// Règle stricte : 10 chiffres uniquement.
  bool _isDialable(String numero) {
    // On nettoie tout ce qui n'est pas un chiffre
    final clean = numero.replaceAll(RegExp(r'[^\d]'), '');
    return clean.length == 10;
  }

  /// Retourne l'icône selon la règle métier
  /// - Fax -> Fax
  /// - Court (<= 5) -> Portable
  /// - Long (10) -> Fixe
  IconData _getIcon(String numero, String? type) {
    if (type?.toLowerCase() == 'fax') return Icons.fax;
    
    final clean = numero.replaceAll(RegExp(r'[^\d]'), '');
    
    if (clean.length <= 5) {
      return Icons.smartphone; // Numéro court interne
    }
    return Icons.phone; // Numéro long standard
  }

  Color _getColor(String? type, bool isDialable) {
    if (!isDialable && type?.toLowerCase() != 'fax') return Colors.grey;
    
    switch (type?.toLowerCase()) {
      case 'mobile': return Colors.blue;
      case 'fax': return Colors.orange;
      case 'bip': return Colors.purple;
      default: return Colors.green;
    }
  }

  Future<void> _dialPhoneNumber(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final Uri dialUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(dialUri)) {
        await launchUrl(dialUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le téléphone'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDialable = _isDialable(contact.numero);
    final icon = _getIcon(contact.numero, contact.type);
    
    // Si c'est un fax, on ne le rend jamais cliquable pour appeler, mais on garde la couleur
    final isFax = contact.type?.toLowerCase() == 'fax';
    final color = _getColor(contact.type, isDialable || isFax);
    
    // Le clic est activé SEULEMENT si c'est composable (10 chiffres) ET que ce n'est pas un fax
    final canTap = isDialable && !isFax;

    return RepaintBoundary(
      child: InkWell(
        onTap: canTap ? () => _dialPhoneNumber(context, contact.numero) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Fond grisé si non cliquable, sinon légèrement coloré
            color: canTap ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canTap ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: canTap || isFax ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.label != null)
                      Text(
                        contact.label!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      contact.numero,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        // Le numéro reste bien visible (noir/gris foncé) même si non cliquable
                        color: canTap || isFax ? color : Colors.grey.shade800,
                      ),
                    ),
                    if (!isDialable && !isFax)
                      Text(
                        'Numéro interne',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              // On n'affiche l'icône d'appel à droite QUE si c'est cliquable
              if (canTap)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}