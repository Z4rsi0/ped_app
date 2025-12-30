import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';
import '../widgets/protocol_block_widgets.dart';
import 'main.dart';

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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement protocoles: $e');
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
            tooltip: 'Recharger',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_protocolService.protocols.isEmpty) {
      return _buildEmptyView();
    }

    return _buildProtocolsList();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun protocole disponible',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _protocolService.protocols.length,
      itemBuilder: (context, index) {
        final protocol = _protocolService.protocols[index];
        return RepaintBoundary(
          child: Card(
            key: ValueKey(protocol.titre),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.description, color: Colors.orange.shade700),
              ),
              title: Text(
                protocol.titre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protocol.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (protocol.version != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'v${protocol.version}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProtocolDetailScreen(protocol: protocol),
                ),
              ),
            ),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.titre),
        backgroundColor: Colors.orange.shade100,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: GlobalWeightSelectorCompact(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête du protocole
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  protocol.description,
                  style: const TextStyle(fontSize: 15),
                ),
                if (protocol.auteur != null || protocol.version != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (protocol.auteur != null)
                        Chip(
                          label: Text(protocol.auteur!),
                          avatar: const Icon(Icons.person, size: 16),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (protocol.auteur != null && protocol.version != null)
                        const SizedBox(width: 8),
                      if (protocol.version != null)
                        Chip(
                          label: Text('v${protocol.version}'),
                          avatar: const Icon(Icons.tag, size: 16),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Blocs du protocole
          ...protocol.blocs.map((block) => ProtocolBlockWidget(block: block)),
        ],
      ),
    );
  }
}