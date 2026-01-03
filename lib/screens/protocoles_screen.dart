import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';
import '../widgets/protocol_block_widgets.dart';
import '../widgets/global_weight_selector.dart';
import '../utils/string_utils.dart';
import '../theme/app_theme.dart';

class ProtocolesScreen extends StatefulWidget {
  const ProtocolesScreen({super.key});

  @override
  State<ProtocolesScreen> createState() => _ProtocolesScreenState();
}

class _ProtocolesScreenState extends State<ProtocolesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ProtocolService _protocolService = ProtocolService();
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _protocolService.loadProtocols();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    List<Protocol> filteredProtocols;
    
    if (_searchQuery.isEmpty) {
      filteredProtocols = _protocolService.protocols;
    } else {
      final scored = _protocolService.protocols.map((p) {
        double scoreTitre = StringUtils.similarity(_searchQuery, p.titre);
        double scoreDesc = StringUtils.similarity(_searchQuery, p.description) * 0.8; 
        return MapEntry(p, scoreTitre > scoreDesc ? scoreTitre : scoreDesc);
      })
      .where((entry) => entry.value > 0.3)
      .toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      filteredProtocols = scored.map((e) => e.key).toList();
    }

    final protocolColors = context.medicalColors;

    return Scaffold(
      // PLUS D'APPBAR ICI (Géré par MainScreen)
      body: Column(
        children: [
          // 1. Barre de recherche (Comme Thérapeutique)
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text('Erreur: $_errorMessage'))
                  : RefreshIndicator( // Ajout du Pull-to-Refresh pour remplacer le bouton de l'AppBar
                      onRefresh: () async {
                        await _protocolService.reloadProtocols();
                        await _loadData();
                      },
                      child: filteredProtocols.isEmpty
                          ? ListView( // ListView pour permettre le scroll/refresh même vide
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
                                              ? 'Aucun protocole disponible' 
                                              : 'Aucun résultat pour "$_searchQuery"',
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

// ... La classe ProtocolDetailScreen doit garder son AppBar car c'est un nouvel écran
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