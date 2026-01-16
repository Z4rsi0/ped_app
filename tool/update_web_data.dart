import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// --- CONFIGURATION ---
const String repoOwner = 'Z4rsi0';
const String repoName = 'ped_app_data';
const String branch = 'main'; // Vérifie si c'est 'main' ou 'master'
const String targetDir = 'web/data';

// --- MAIN ---
void main() async {
  print('🚀 Démarrage de la mise à jour des données Web...');

  // 1. Récupérer le Token (indispensable pour les repos privés et éviter les limites API)
  final token = _getEnvToken();
  if (token == null) {
    print('⚠️ ATTENTION : Pas de GITHUB_TOKEN trouvé dans .env. Les appels peuvent échouer si le repo est privé.');
  }

  // 2. Nettoyer le dossier cible
  final dir = Directory(targetDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
    print('🗑️ Dossier $targetDir nettoyé.');
  }
  dir.createSync(recursive: true);

  final Map<String, dynamic> listing = {};

  try {
    // 3. Télécharger les fichiers racines
    await _downloadFile('assets/annuaire.json', 'annuaire.json', token);
    await _downloadFile('assets/medicaments_pediatrie.json', 'medicaments_pediatrie.json', token);

    // 4. Télécharger les dossiers et construire le listing
    listing['protocoles'] = await _downloadFolder('assets/protocoles', 'protocoles', token);
    listing['pocus'] = await _downloadFolder('assets/pocus', 'pocus', token);

    // 5. Générer listing.json
    final listingFile = File('$targetDir/listing.json');
    listingFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(listing));
    print('✅ listing.json généré avec succès.');

    print('\n🎉 Terminé ! Les données sont prêtes pour "flutter build web".');
  } catch (e) {
    print('\n❌ ERREUR FATALE : $e');
    exit(1);
  }
}

// --- FONCTIONS UTILITAIRES ---

/// Lit le token depuis le fichier .env sans dépendance Flutter
String? _getEnvToken() {
  final envFile = File('.env');
  if (!envFile.existsSync()) return null;
  
  final lines = envFile.readAsLinesSync();
  for (var line in lines) {
    if (line.startsWith('GITHUB_TOKEN=')) {
      return line.split('=')[1].trim();
    }
  }
  return null;
}

/// Télécharge un fichier unique
Future<void> _downloadFile(String remotePath, String localName, String? token) async {
  final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$remotePath?ref=$branch');
  final response = await http.get(url, headers: _headers(token));

  if (response.statusCode != 200) throw Exception('Impossible de trouver $remotePath (${response.statusCode})');

  final json = jsonDecode(response.body);
  final downloadUrl = json['download_url'];

  final contentResp = await http.get(Uri.parse(downloadUrl), headers: _headers(token));
  File('$targetDir/$localName').writeAsStringSync(utf8.decode(contentResp.bodyBytes));
  print('⬇️ Téléchargé : $localName');
}

/// Télécharge tout un dossier et retourne la liste des fichiers
Future<List<String>> _downloadFolder(String remoteDir, String localSubDir, String? token) async {
  final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$remoteDir?ref=$branch');
  final response = await http.get(url, headers: _headers(token));

  if (response.statusCode != 200) throw Exception('Impossible de lister $remoteDir (${response.statusCode})');

  final List<dynamic> files = jsonDecode(response.body);
  final List<String> downloadedFiles = [];

  // Créer le sous-dossier local (ex: web/data/protocoles)
  Directory('$targetDir/$localSubDir').createSync(recursive: true);

  for (var file in files) {
    if (file['type'] == 'file' && file['name'].toString().endsWith('.json')) {
      final name = file['name'];
      final downloadUrl = file['download_url'];
      
      // Téléchargement du contenu brut
      final contentResp = await http.get(Uri.parse(downloadUrl), headers: _headers(token));
      
      File('$targetDir/$localSubDir/$name').writeAsStringSync(utf8.decode(contentResp.bodyBytes));
      downloadedFiles.add(name);
      print('  📄 $localSubDir/$name');
    }
  }
  return downloadedFiles;
}

Map<String, String> _headers(String? token) {
  return {
    'Accept': 'application/vnd.github.v3+json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}