import 'dart:io';
import 'dart:async';

// --- CONFIGURATION ---
const String deviceId = '23078PND5G'; // Ton ID de device spécifique

// Variable globale pour stocker le chemin racine du projet
late String projectRoot;

void main() async {
  // 1. Calculer la racine du projet (Le dossier parent de ce script)
  // On prend le chemin du script en cours, on récupère son dossier (tool), puis le parent (ped_app)
  final scriptFile = File(Platform.script.toFilePath());
  projectRoot = scriptFile.parent.parent.path;

  // 2. Vérification de sécurité
  final pubspec = File('$projectRoot/pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('❌ Erreur critique : Impossible de localiser la racine du projet.');
    print('   Chemin calculé : $projectRoot');
    print('   Vérifiez que ce script est bien dans le dossier /tool/ du projet.');
    exit(1);
  }

  print('📂 Racine du projet détectée : $projectRoot');

  // Définition des options du menu
  final options = [
    MenuOption(
      label: '🚀 WEB : Update Data + Build + Deploy Firebase',
      description: 'Mise à jour JSON > Build Release > Envoi en prod',
      action: _runWebPipeline,
    ),
    MenuOption(
      label: '🐛 ANDROID : Debug Run (Device spécifique)',
      description: 'flutter run -v -d $deviceId',
      action: () => _runCommand('flutter', ['run', '-v', '-d', deviceId]),
    ),
    MenuOption(
      label: '📦 ANDROID : Build APK Release (ARM64)',
      description: 'flutter build apk --release --target-platform android-arm64',
      action: () => _runCommand('flutter', ['build', 'apk', '--release', '--target-platform', 'android-arm64', '-v']),
    ),
    MenuOption(
      label: '📲 ANDROID : Installer dernière release',
      description: 'flutter install',
      action: () => _runCommand('flutter', ['install']),
    ),
    MenuOption(
      label: '❌ Quitter',
      description: '',
      action: () => Future.value(true),
    ),
  ];

  // Affichage du menu (Boucle)
  int selectedIndex = -1;
  while (selectedIndex < 0 || selectedIndex >= options.length) {
    if (Platform.isWindows) {
      print('\n' * 5); // Saut de ligne simple sur Windows
    } else {
      try {
        stdout.write('\x1B[2J\x1B[0;0H'); // Clear console UNIX
      } catch (e) {
        print('\n' * 20);
      }
    }

    _printHeader();
    
    for (int i = 0; i < options.length; i++) {
      print('  [${i + 1}] ${options[i].label}');
      if (options[i].description.isNotEmpty) {
        print('      Run: ${options[i].description}');
      }
      print('');
    }

    stdout.write('👉 Choisissez une option (1-${options.length}) : ');
    
    final input = stdin.readLineSync();
    if (input != null && int.tryParse(input) != null) {
      final choice = int.parse(input);
      if (choice >= 1 && choice <= options.length) {
        selectedIndex = choice - 1;
      }
    }
  }
  
  // Exécution
  print('\n🔄 Lancement de : ${options[selectedIndex].label}...\n');
  final success = await options[selectedIndex].action();

  if (!success) {
    print('\n❌ Une erreur est survenue pendant l\'exécution.');
    exit(1);
  } else {
    print('\n✅ Opération terminée avec succès.');
    exit(0);
  }
}

void _printHeader() {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║              🛠️  PED APP - BUILD MENU  🛠️                 ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
}

// --- PIPELINES SPÉCIFIQUES ---

Future<bool> _runWebPipeline() async {
  // Note : On utilise 'dart run tool/...' car on est positionné à la racine grâce à workingDirectory
  print('1️⃣  [1/3] Mise à jour des données Web...');
  if (!await _runCommand('dart', ['run', 'tool/update_web_data.dart'])) return false;

  print('\n2️⃣  [2/3] Compilation Web (Release)...');
  if (!await _runCommand('flutter', ['build', 'web', '--release'])) return false;

  print('\n3️⃣  [3/3] Déploiement Firebase...');
  // Sur Windows, 'firebase' est souvent un script batch, runInShell est crucial
  if (!await _runCommand('firebase', ['deploy'])) {
    return false;
  }

  return true;
}

// --- UTILITAIRES SYSTÈME ---

Future<bool> _runCommand(String executable, List<String> args) async {
  try {
    final process = await Process.start(
      executable,
      args,
      mode: ProcessStartMode.inheritStdio,
      workingDirectory: projectRoot, // ✅ FORCE l'exécution dans le dossier racine
      runInShell: true,              // ✅ INDISPENSABLE pour trouver les commandes (flutter, firebase...)
    );
    final exitCode = await process.exitCode;
    return exitCode == 0;
  } catch (e) {
    print('❌ Erreur système lors de l\'exécution de $executable: $e');
    return false;
  }
}

class MenuOption {
  final String label;
  final String description;
  final Future<bool> Function() action;

  MenuOption({required this.label, required this.description, required this.action});
}