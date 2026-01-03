import 'dart:math';

class StringUtils {
  /// Normalise une chaîne (minuscule, sans accents)
  static String normalize(String input) {
    if (input.isEmpty) return '';
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .trim();
  }

  /// Calcule un score de similarité entre 0.0 et 1.0
  /// Utilise une approche simple basée sur l'inclusion et la distance
  static double similarity(String query, String target) {
    final nQuery = normalize(query);
    final nTarget = normalize(target);

    if (nQuery.isEmpty) return 0.0;
    if (nTarget.isEmpty) return 0.0;
    
    // Correspondance exacte ou préfixe (Score maximal)
    if (nTarget == nQuery) return 1.0;
    if (nTarget.startsWith(nQuery)) return 0.9;
    
    // Inclusion (Score élevé)
    if (nTarget.contains(nQuery)) return 0.8;

    // Tolérance aux fautes (Distance de Levenshtein simplifiée)
    // On ne lance ce calcul coûteux que si les chaînes sont proches en longueur
    if ((nTarget.length - nQuery.length).abs() > 3) return 0.0;

    int dist = _levenshtein(nQuery, nTarget);
    double maxLen = max(nQuery.length, nTarget.length).toDouble();
    if (maxLen == 0) return 0.0;
    
    return 1.0 - (dist / maxLen);
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) v0[i] = i;

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }

    return v1[t.length];
  }
}