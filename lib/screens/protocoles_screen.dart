import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';
import '../widgets/protocol_block_widgets.dart';
import '../widgets/global_weight_selector.dart';

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

    // Filtrage local pour la recherche
    final filteredProtocols = _protocolService.protocols.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.titre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Protocoles"),
        backgroundColor: Colors.orange.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _protocolService.reloadProtocols();
              _loadData();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un protocole...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Erreur: $_errorMessage'))
              : filteredProtocols.isEmpty
                  ? const Center(child: Text('Aucun protocole'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredProtocols.length,
                      itemBuilder: (context, index) {
                        final protocol = filteredProtocols[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(Icons.description, color: Colors.orange),
                            ),
                            title: Text(protocol.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}

class ProtocolDetailScreen extends StatelessWidget {
  final Protocol protocol;

  const ProtocolDetailScreen({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    // Calcul du nombre total d'items (Header + Blocs)
    // index 0 = Header
    // index 1..N = Blocs
    
    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.titre),
        backgroundColor: Colors.orange.shade100,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: GlobalWeightSelectorCompact()),
          ),
        ],
      ),
      // OPTIMISATION: ListView.builder pour rendu paresseux (Lazy Loading)
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 1 + protocol.blocs.length, // +1 pour le header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          final block = protocol.blocs[index - 1];
          return ProtocolBlockWidget(block: block);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(protocol.description),
          if (protocol.auteur != null) ...[
            const SizedBox(height: 8),
            Text('Auteur: ${protocol.auteur}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}