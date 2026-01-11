import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'providers/weight_provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart'; // Nouvelle localisation

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Silent fail pour env
  }

  // Init rapide de Hive (pas de téléchargement ici)
  try {
    await StorageService().init();
  } catch (e) {
    debugPrint('❌ Erreur StorageService: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => WeightProvider(),
      child: const PediatricApp(),
    ),
  );
}

class PediatricApp extends StatelessWidget {
  const PediatricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Massio Ped',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}