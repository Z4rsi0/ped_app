import 'package:flutter/material.dart';
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
  // Plus besoin de AutomaticKeepAliveClientMixin car la lecture Hive est instantanée
  final StorageService _storage = StorageService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // 1. Lecture Sync depuis Hive (Instantané)
    final allProtocols = _storage.getProtocols();
    final protocolColors = context.medicalColors;

    // 2. Filtrage
    List<Protocol> filteredProtocols;
    
    if (_searchQuery.isEmpty) {
      filteredProtocols = allProtocols;
    } else {
      final scored = allProtocols.map((p) {
        double scoreTitre = StringUtils.similarity(_searchQuery, p.titre);
        double scoreDesc = StringUtils.similarity(_searchQuery, p.description) * 0.8; 
        return MapEntry(p, scoreTitre > scoreDesc ? scoreTitre : scoreDesc);
      })
      .where((entry) => entry.value > 0.3)
      .toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      filteredProtocols = scored.map((e) => e.key).toList();
    }

    return Scaffold(
      // L'AppBar est gérée par le MainScreen, on a juste le corps ici
      body: Column(
        children: [
          // 1. Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un protocole...',
                prefixIcon: Icon(Icons.search, color: context.colors.onSurfaceVariant),
                fillColor: context.colors.surfaceContainerHigh, 
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      ) 
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // 2. Liste des résultats
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Le pull-to-refresh force une synchro réseau
                await DataSyncService.syncAllData();
                // On force la reconstruction pour réafficher les nouvelles données
                if (mounted) setState(() {}); 
              },
              child: filteredProtocols.isEmpty
                  ? ListView( // ListView permet le scroll même vide (pour le refresh)
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: context.colors.outline),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? (allProtocols.isEmpty 
                                          ? 'Aucun protocole.\nTirez pour synchroniser.' 
                                          : 'Aucun protocole disponible')
                                      : 'Aucun résultat pour "$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredProtocols.length,
                      itemBuilder: (context, index) {
                        final protocol = filteredProtocols[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: protocolColors.protocolContainer,
                              child: Icon(Icons.description, color: protocolColors.protocolOnContainer),
                            ),
                            title: Text(
                              protocol.titre, 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              protocol.description, 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProtocolDetailScreen(protocol: protocol),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProtocolDetailScreen extends StatelessWidget {
  final Protocol protocol;

  const ProtocolDetailScreen({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    final protocolColors = context.medicalColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.titre),
        backgroundColor: protocolColors.protocolContainer,
        foregroundColor: protocolColors.protocolOnContainer,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: GlobalWeightSelectorCompact()),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 1 + protocol.blocs.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context);
          }
          final block = protocol.blocs[index - 1];
          return ProtocolBlockWidget(block: block);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final protocolColors = context.medicalColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: protocolColors.protocolContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: protocolColors.protocolContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: protocolColors.protocolPrimary),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: protocolColors.protocolPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(protocol.description),
          if (protocol.auteur != null || protocol.version != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (protocol.auteur != null)
                  Chip(
                    label: Text(protocol.auteur!),
                    avatar: const Icon(Icons.person, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                if (protocol.version != null)
                  Chip(
                    label: Text('v${protocol.version}'),
                    avatar: const Icon(Icons.tag, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}