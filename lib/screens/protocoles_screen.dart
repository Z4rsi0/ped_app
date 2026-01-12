import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/protocol_model.dart';
import '../services/storage_service.dart';
import '../services/data_sync_service.dart';
import '../widgets/protocol_block_widgets.dart';
import '../widgets/global_weight_selector.dart';
import '../utils/string_utils.dart';
import '../theme/app_theme.dart';

class ProtocolesScreen extends StatefulWidget {
  const ProtocolesScreen({super.key});

  @override
  State<ProtocolesScreen> createState() => _ProtocolesScreenState();
}

class _ProtocolesScreenState extends State<ProtocolesScreen> {
  final StorageService _storage = StorageService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Sémantique Protocoles (Orange)
    final theme = context.medicalColors;
    final primaryColor = theme.protocolPrimary;
    final containerColor = theme.protocolContainer;

    return ValueListenableBuilder<Box<Protocol>>(
      valueListenable: _storage.protocolListenable,
      builder: (context, box, _) {
        final allProtocols = box.values.toList();
        
        // --- LOGIQUE DE RECHERCHE ---
        List<Protocol> searchResults = [];
        bool isSearching = _searchQuery.isNotEmpty;

        if (isSearching) {
          final scored = allProtocols.map((p) {
            double scoreTitre = StringUtils.similarity(_searchQuery, p.titre);
            double scoreDesc = StringUtils.similarity(_searchQuery, p.description) * 0.8; 
            // On cherche aussi dans la catégorie
            double scoreCat = p.categorie != null ? StringUtils.similarity(_searchQuery, p.categorie!) * 0.6 : 0.0;
            
            double maxScore = [scoreTitre, scoreDesc, scoreCat].reduce((a, b) => a > b ? a : b);
            return MapEntry(p, maxScore);
          })
          .where((entry) => entry.value > 0.3)
          .toList();

          scored.sort((a, b) => b.value.compareTo(a.value));
          searchResults = scored.map((e) => e.key).toList();
        }

        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un protocole...',
                  prefixIcon: Icon(Icons.search, color: context.colors.onSurfaceVariant),
                  fillColor: context.colors.surfaceContainerHigh, 
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  suffixIcon: isSearching
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')) 
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: _buildBody(
                  context, 
                  isSearching ? searchResults : allProtocols, 
                  isSearching, 
                  primaryColor, 
                  containerColor
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, List<Protocol> list, bool isSearching, Color primary, Color bg) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isSearching ? 'Aucun résultat' : (list.isEmpty ? 'Aucun protocole' : ''),
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      );
    }

    // MODE RECHERCHE : Liste plate
    if (isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildProtocolTile(context, list[index], primary, bg);
        },
      );
    }

    // MODE DÉFAUT : Dossiers par Catégorie
    final grouped = <String, List<Protocol>>{};
    for (var p in list) {
      final cat = p.categorie ?? 'Autres';
      grouped.putIfAbsent(cat, () => []).add(p);
    }
    
    final sortedCategories = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final protocols = grouped[category]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(Icons.folder_copy, color: primary, size: 20),
              ),
              title: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: protocols.map((p) => _buildProtocolTile(context, p, primary, bg, isSubItem: true)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProtocolTile(BuildContext context, Protocol p, Color primary, Color bg, {bool isSubItem = false}) {
    return Card(
      elevation: 0,
      margin: isSubItem 
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4) 
          : const EdgeInsets.only(bottom: 12),
      color: isSubItem ? context.colors.surfaceContainerLow : context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSubItem ? BorderSide.none : BorderSide(color: context.colors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isSubItem 
            ? Icon(Icons.description, size: 20, color: context.colors.onSurfaceVariant)
            : CircleAvatar(backgroundColor: bg, child: Icon(Icons.description, color: primary)),
        title: Text(p.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: p.description.isNotEmpty 
            ? Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis) 
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProtocolDetailScreen(protocol: p)),
        ),
      ),
    );
  }
}

// L'écran de détail reste inchangé, mais on le garde accessible pour l'import dans PocusScreen
class ProtocolDetailScreen extends StatelessWidget {
  final Protocol protocol;
  const ProtocolDetailScreen({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    // Sémantique par défaut (Orange)
    // Note : PocusDetailScreen dans PocusScreen utilise le thème Teal.
    final protocolColors = context.medicalColors;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.titre),
        backgroundColor: protocolColors.protocolContainer,
        foregroundColor: protocolColors.protocolOnContainer,
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.medicalColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.protocolContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.protocolContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(protocol.description, style: TextStyle(fontSize: 15, color: context.colors.onSurface)),
          if (protocol.auteur != null) ...[
            const SizedBox(height: 8),
            Chip(label: Text(protocol.auteur!), avatar: const Icon(Icons.person, size: 14)),
          ]
        ],
      ),
    );
  }
}