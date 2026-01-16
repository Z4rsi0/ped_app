import 'dart:io';
import 'dart:async';

// --- CONFIGURATION ---
const String deviceId = '23078PND5G'; // Ton ID de device spécifique

void main() async {
  // On s'assure d'être dans le bon dossier
  if (!File('pubspec.yaml').existsSync()) {
    print('❌ Erreur : Ce script doit être lancé depuis la racine du projet Flutter.');
    exit(1);
  }

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

  // Affichage du menu
  int selectedIndex = -1;
  while (selectedIndex < 0 || selectedIndex >= options.length) {
    // Nettoyage console (compatible Windows/Mac/Linux)
    if (Platform.isWindows) {
      // Sur Windows, on imprime juste des sauts de ligne pour "vider" visuellement
      print('\n' * 50);
    } else {
      stdout.write('\x1B[2J\x1B[0;0H');
    }

    _printHeader();
    
    for (int i = 0; i < options.length; i++) {
      print('  [${i + 1}] ${options[i].label}');
      if (options[i].description.isNotEmpty) {
        print('      Run: ${options[i].description}');
      }
      print(''); // Ligne vide
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
  
  // Exécution de l'action choisie
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
  print('║               🛠️  PED APP - BUILD MENU  🛠️                 ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
}

// --- PIPELINES SPÉCIFIQUES ---

/// Pipeline Web complet : Update Data -> Build -> Deploy
Future<bool> _runWebPipeline() async {
  // 1. Mise à jour des données (Script Dart)
  print('1️⃣  [1/3] Mise à jour des données Web...');
  if (!await _runCommand('dart', ['run', 'tool/update_web_data.dart'])) return false;

  // 2. Build Web
  print('\n2️⃣  [2/3] Compilation Web (Release)...');
  if (!await _runCommand('flutter', ['build', 'web', '--release'])) return false;

  // 3. Deploy Firebase
  print('\n3️⃣  [3/3] Déploiement Firebase...');
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
    );
    final exitCode = await process.exitCode;
    return exitCode == 0;
  } catch (e) {
    print('Erreur lors de l\'exécution de $executable: $e');
    return false;
  }
}

class MenuOption {
  final String label;
  final String description;
  final Future<bool> Function() action;

  MenuOption({required this.label, required this.description, required this.action});
}