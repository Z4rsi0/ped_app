import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/annuaire_model.dart';
import '../services/storage_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';

class AnnuaireScreen extends StatefulWidget {
  const AnnuaireScreen({super.key});

  @override
  State<AnnuaireScreen> createState() => _AnnuaireScreenState();
}

class _AnnuaireScreenState extends State<AnnuaireScreen> {
  final StorageService _storage = StorageService();
  bool isInterne = true;
  final TextEditingController searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  void _filterServices(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = query);
    });
  }

  void _toggleMode(bool interne) => setState(() => isInterne = interne);

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annuaireColors = context.medicalColors;

    // 🔥 REACTIVITÉ HIVE
    return ValueListenableBuilder<Box<Annuaire>>(
      valueListenable: _storage.annuaireListenable,
      builder: (context, box, _) {
        final annuaire = box.isNotEmpty ? box.getAt(0) : null;
        List<Service> services = [];
        if (annuaire != null) {
          services = isInterne ? annuaire.interne : annuaire.externe;
        }

        List<Service> filteredServices;
        if (_query.isEmpty) {
          filteredServices = services;
        } else {
          final q = _query.toLowerCase();
          filteredServices = services.where((s) {
            if (s.nom.toLowerCase().contains(q)) return true;
            if (s.description?.toLowerCase().contains(q) ?? false) return true;
            for (var contact in s.contacts) {
              if (contact.label?.toLowerCase().contains(q) ?? false) return true;
              if (contact.numero.contains(q)) return true;
            }
            return false;
          }).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Rechercher un service ou contact",
                  prefixIcon: const Icon(Icons.search),
                  fillColor: context.colors.surfaceContainerHigh,
                  filled: true,
                  suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); _filterServices(''); }) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: _filterServices,
              ),
            ),
            
            _buildModeSelector(context, annuaireColors),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: filteredServices.isEmpty
                    ? ListView(
                        children: [
                           SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(annuaire == null ? 'Chargement...' : 'Aucun service', style: TextStyle(color: context.colors.onSurfaceVariant)),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          return ServiceCard(
                            key: ValueKey(filteredServices[index].nom),
                            service: filteredServices[index],
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

  Widget _buildModeSelector(BuildContext context, MedicalColors colors) {
    return Container(
      color: colors.annuaireContainer.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildModeButton(context, 'Interne', isInterne, Icons.business, () => _toggleMode(true))),
          const SizedBox(width: 12),
          Expanded(child: _buildModeButton(context, 'Externe', !isInterne, Icons.public, () => _toggleMode(false))),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String label, bool isActive, IconData icon, VoidCallback onTap) {
    final colors = context.medicalColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.annuairePrimary : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? colors.annuairePrimary : context.colors.outline, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : context.colors.onSurface),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : context.colors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// --- PARTIE CARTES DÉTAILLÉES (Style v1 restauré) ---

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
              leading: CircleAvatar(backgroundColor: annuaireColors.annuaireContainer, child: Icon(Icons.phone_in_talk, color: annuaireColors.annuaireOnContainer)),
              title: Text(widget.service.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: widget.service.description != null ? Text(widget.service.description!, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13)) : null,
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: annuaireColors.annuairePrimary),
              onTap: () => setState(() => isExpanded = !isExpanded),
            ),
            if (isExpanded)
              Container(
                decoration: BoxDecoration(color: annuaireColors.annuaireContainer.withValues(alpha: 0.1), border: Border(top: BorderSide(color: context.colors.outlineVariant))),
                child: Column(children: widget.service.contacts.map((contact) => ContactTile(key: ValueKey(contact.numero), contact: contact)).toList()),
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

  // Règle stricte demandée : 10 chiffres pour être cliquable
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