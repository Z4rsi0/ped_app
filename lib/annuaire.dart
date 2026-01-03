import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/annuaire_model.dart';
import 'services/data_sync_service.dart';
import 'theme/app_theme.dart';

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
        if (s.nom.toLowerCase().contains(query)) return true;
        if (s.description?.toLowerCase().contains(query) ?? false) return true;
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
    super.build(context);
    final annuaireColors = context.medicalColors;

    return Scaffold(
      // PLUS D'APPBAR ICI (Géré par MainScreen)
      body: Column(
        children: [
          // 1. Barre de recherche (Comme Thérapeutique)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un service ou contact",
                prefixIcon: const Icon(Icons.search),
                fillColor: context.colors.surfaceContainerHigh,
                filled: true,
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterServices('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _filterServices,
            ),
          ),
          
          // 2. Sélecteur
          _buildModeSelector(annuaireColors),

          // 3. Liste
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(MedicalColors colors) {
    return Container(
      color: colors.annuaireContainer.withValues(alpha: 0.3),
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
    final annuaireColors = context.medicalColors;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? annuaireColors.annuairePrimary : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? annuaireColors.annuairePrimary : context.colors.outline,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : context.colors.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Reste des méthodes _buildServicesList, ServiceCard, ContactTile inchangées mais nécessaires au fichier)
  Widget _buildServicesList() {
    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.colors.outline),
            const SizedBox(height: 16),
            Text('Aucun service trouvé', style: TextStyle(fontSize: 16, color: context.colors.onSurfaceVariant)),
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
    final annuaireColors = context.medicalColors;
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: annuaireColors.annuaireContainer,
                child: Icon(Icons.phone_in_talk, color: annuaireColors.annuaireOnContainer),
              ),
              title: Text(widget.service.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: widget.service.description != null ? Text(widget.service.description!, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)) : null,
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: annuaireColors.annuairePrimary),
              onTap: () => setState(() => isExpanded = !isExpanded),
            ),
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: annuaireColors.annuaireContainer.withValues(alpha: 0.1),
                  border: Border(top: BorderSide(color: context.colors.outlineVariant)),
                ),
                child: Column(
                  children: widget.service.contacts.map((contact) => ContactTile(key: ValueKey(contact.numero), contact: contact)).toList(),
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

  bool _isDialable(String numero) => numero.replaceAll(RegExp(r'[^\d]'), '').length == 10;
  
  IconData _getIcon(String numero, String? type) {
    if (type?.toLowerCase() == 'fax') return Icons.fax;
    if (numero.replaceAll(RegExp(r'[^\d]'), '').length <= 5) return Icons.smartphone;
    return Icons.phone;
  }

  Color _getColor(BuildContext context, String? type, bool isDialable) {
    final theme = context.medicalColors;
    if (!isDialable && type?.toLowerCase() != 'fax') return context.colors.outline;
    switch (type?.toLowerCase()) {
      case 'mobile': return context.colors.primary; 
      case 'fax': return theme.protocolPrimary; 
      case 'bip': return theme.calculusPrimary; 
      default: return theme.annuairePrimary; 
    }
  }

  Future<void> _dialPhoneNumber(BuildContext context, String phoneNumber) async {
    final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'[^\d]'), ''));
    if (await canLaunchUrl(dialUri)) await launchUrl(dialUri);
    else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le téléphone'), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDialable = _isDialable(contact.numero);
    final isFax = contact.type?.toLowerCase() == 'fax';
    final color = _getColor(context, contact.type, isDialable || isFax);
    final canTap = isDialable && !isFax;

    return RepaintBoundary(
      child: InkWell(
        onTap: canTap ? () => _dialPhoneNumber(context, contact.numero) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: canTap ? color.withValues(alpha: 0.1) : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: canTap ? color.withValues(alpha: 0.3) : context.colors.outlineVariant, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: canTap || isFax ? color : context.colors.outline, borderRadius: BorderRadius.circular(8)),
                child: Icon(_getIcon(contact.numero, contact.type), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.label != null) Text(contact.label!, style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    Text(contact.numero, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: canTap || isFax ? color : context.colors.onSurface)),
                    if (!isDialable && !isFax) Text('Numéro interne', style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              if (canTap) Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.call, color: Colors.white, size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}