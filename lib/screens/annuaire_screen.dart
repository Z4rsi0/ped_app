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

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
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

        // Filtrage
        List<Service> filteredServices;
        if (_query.isEmpty) {
          filteredServices = services;
        } else {
          final q = _query.toLowerCase();
          filteredServices = services.where((s) {
            return s.nom.toLowerCase().contains(q) || 
                   s.contacts.any((c) => c.numero.contains(q));
          }).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Rechercher...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() => _query = ''); }) : null,
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),
            
            // Sélecteur Mode
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _ModeBtn("Interne", isInterne, () => setState(() => isInterne = true))),
                  Expanded(child: _ModeBtn("Externe", !isInterne, () => setState(() => isInterne = false))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: filteredServices.isEmpty
                    ? ListView(
                        children: [
                           SizedBox(height: 200, child: Center(child: Text(annuaire == null ? 'Chargement...' : 'Aucun service')))
                        ],
                      )
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) => _ServiceTile(service: filteredServices[index]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? context.medicalColors.annuairePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label, 
            style: TextStyle(
              color: active ? Colors.white : context.colors.onSurface, 
              fontWeight: FontWeight.bold
            )
          )
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(service.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: service.description != null ? Text(service.description!) : null,
        children: service.contacts.map((c) => ListTile(
          leading: const Icon(Icons.phone),
          title: Text(c.numero, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: c.label != null ? Text(c.label!) : null,
          trailing: const Icon(Icons.call, color: Colors.green),
          onTap: () => launchUrl(Uri.parse('tel:${c.numero}')),
        )).toList(),
      ),
    );
  }
}