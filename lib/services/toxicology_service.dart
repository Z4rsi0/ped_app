import '../models/toxic_agent.dart';
import 'storage_service.dart';
import '../utils/string_utils.dart';

/// Service responsable uniquement de l'accès et de la recherche des données toxiques.
class ToxicologyService {
  final StorageService _storage = StorageService();

  /// Recherche les agents toxiques (Nom + Mots clés)
  List<ToxicAgent> searchAgents(String query) {
    // On délègue la récupération brute au storage
    final allAgents = _storage.getToxicAgents();

    if (query.isEmpty) return [];

    final q = StringUtils.normalize(query);

    return allAgents.where((agent) {
      // 1. Recherche dans le nom
      if (StringUtils.normalize(agent.nom).contains(q)) return true;
      
      // 2. Recherche dans les synonymes/mots-clés
      for (var keyword in agent.motsCles) {
        if (StringUtils.normalize(keyword).contains(q)) return true;
      }
      return false;
    }).toList();
  }
  
}