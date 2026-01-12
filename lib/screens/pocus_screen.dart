import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/protocol_model.dart';
import '../services/storage_service.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/protocol_block_widgets.dart'; // Nécessaire pour les blocs
import '../widgets/global_weight_selector.dart'; // Nécessaire pour le header

class PocusScreen extends StatefulWidget {
  const PocusScreen({super.key});

  @override
  State<PocusScreen> createState() => _PocusScreenState();
}

class _PocusScreenState extends State<PocusScreen> {
  final StorageService _storage = StorageService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final medColors = context.medicalColors;
    // Sémantique Pocus
    final primaryColor = medColors.pocusPrimary;
    final containerColor = medColors.pocusContainer;

    return ValueListenableBuilder<Box<Protocol>>(
      valueListenable: _storage.pocusListenable,
      builder: (context, box, _) {
        final allPocus = box.values.toList();
        
        List<Protocol> filteredList;
        if (_searchQuery.isEmpty) {
          filteredList = allPocus;
        } else {
          final q = _searchQuery.toLowerCase();
          filteredList = allPocus.where((p) {
            return p.titre.toLowerCase().contains(q) || 
                   p.description.toLowerCase().contains(q);
          }).toList();
        }

        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher une fiche écho...',
                  prefixIcon: Icon(Icons.search, color: context.colors.onSurfaceVariant),
                  fillColor: context.colors.surfaceContainerHigh,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')) 
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            
            // Contenu
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waves, size: 64, color: context.colors.outline.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Aucune fiche POCUS.\nConnectez-vous pour synchroniser.' 
                                  : 'Aucun résultat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final protocol = filteredList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: context.colors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.colors.outlineVariant),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: containerColor,
                                child: Icon(Icons.waves, color: primaryColor),
                              ),
                              title: Text(
                                protocol.titre, 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: protocol.description.isNotEmpty 
                                  ? Text(protocol.description, maxLines: 1, overflow: TextOverflow.ellipsis) 
                                  : null,
                              trailing: Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Navigation vers la vue détail TEAL
                                  builder: (_) => PocusDetailScreen(protocol: protocol)
                                ),
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

// ------------------------------------------
// VUE DÉTAIL DÉDIÉE POCUS (Thème Teal)
// ------------------------------------------
class PocusDetailScreen extends StatelessWidget {
  final Protocol protocol;
  const PocusDetailScreen({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    // On force la couleur primaire de cette page en Teal
    // Astuce : On wrappe le Scaffold dans un Theme qui surcharge la couleur primaire
    // pour que les sous-widgets (SectionBlock) s'adaptent automatiquement.
    final medColors = context.medicalColors;
    final tealTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: medColors.pocusPrimary,
        onPrimary: Colors.white,
      ),
    );

    return Theme(
      data: tealTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(protocol.titre),
          // AppBar Teal
          backgroundColor: medColors.pocusContainer,
          foregroundColor: medColors.pocusOnContainer,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8), 
              child: GlobalWeightSelector(), 
            )
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 1 + protocol.blocs.length,
          itemBuilder: (context, index) {
            if (index == 0) return _buildHeader(context);
            return ProtocolBlockWidget(block: protocol.blocs[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final medColors = context.medicalColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: medColors.pocusContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: medColors.pocusContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: medColors.pocusPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  protocol.description, 
                  style: TextStyle(fontSize: 15, color: context.colors.onSurface),
                ),
              ),
            ],
          ),
          if (protocol.auteur != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(protocol.auteur!), 
              avatar: const Icon(Icons.person, size: 14),
              backgroundColor: context.colors.surface,
              side: BorderSide.none,
            ),
          ]
        ],
      ),
    );
  }
}