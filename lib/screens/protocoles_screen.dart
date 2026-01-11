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
    final protocolColors = context.medicalColors;

    return ValueListenableBuilder<Box<Protocol>>(
      valueListenable: _storage.protocolListenable,
      builder: (context, box, _) {
        final allProtocols = box.values.toList();
        
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

        return Column(
          children: [
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
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')) 
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await DataSyncService.syncAllData(),
                child: filteredProtocols.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                _searchQuery.isEmpty 
                                    ? (allProtocols.isEmpty ? 'Chargement...' : 'Aucun protocole')
                                    : 'Aucun résultat',
                                style: TextStyle(color: context.colors.onSurfaceVariant),
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
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: protocolColors.protocolContainer,
                                child: Icon(Icons.description, color: protocolColors.protocolOnContainer),
                              ),
                              title: Text(protocol.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(protocol.description, maxLines: 2, overflow: TextOverflow.ellipsis),
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
        );
      },
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
        // CORRECTION ICI : Utilisation de GlobalWeightSelector (version complète)
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