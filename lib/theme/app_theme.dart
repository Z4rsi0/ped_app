import 'package:flutter/material.dart';

/// Extension de thème pour gérer les couleurs sémantiques médicales
@immutable
class MedicalColors extends ThemeExtension<MedicalColors> {
  // Sémantique : Médicaments (Bleu)
  final Color medicamentPrimary;
  final Color medicamentContainer;
  final Color medicamentOnContainer;

  // Sémantique : Protocoles (Orange)
  final Color protocolPrimary;
  final Color protocolContainer;
  final Color protocolOnContainer;

  // Sémantique : Annuaire (Vert)
  final Color annuairePrimary;
  final Color annuaireContainer;
  final Color annuaireOnContainer;

  // Sémantique : Calculs (Violet)
  final Color calculusPrimary;
  final Color calculusContainer;
  final Color calculusOnContainer;

  // NOUVEAU : Sémantique Pocus (Teal / Sarcelle)
  final Color pocusPrimary;
  final Color pocusContainer;
  final Color pocusOnContainer;

  // Sémantique : Alerte (Rouge)
  final Color alertePrimary;
  final Color alerteContainer;
  final Color alerteOnContainer;

  const MedicalColors({
    required this.medicamentPrimary,
    required this.medicamentContainer,
    required this.medicamentOnContainer,
    required this.protocolPrimary,
    required this.protocolContainer,
    required this.protocolOnContainer,
    required this.annuairePrimary,
    required this.annuaireContainer,
    required this.annuaireOnContainer,
    required this.calculusPrimary,
    required this.calculusContainer,
    required this.calculusOnContainer,
    required this.pocusPrimary,     // Nouveau champ
    required this.pocusContainer,   // Nouveau champ
    required this.pocusOnContainer, // Nouveau champ
    required this.alertePrimary,
    required this.alerteContainer,
    required this.alerteOnContainer,
  });

  @override
  MedicalColors copyWith({
    Color? medicamentPrimary,
    Color? medicamentContainer,
    Color? medicamentOnContainer,
    Color? protocolPrimary,
    Color? protocolContainer,
    Color? protocolOnContainer,
    Color? annuairePrimary,
    Color? annuaireContainer,
    Color? annuaireOnContainer,
    Color? calculusPrimary,
    Color? calculusContainer,
    Color? calculusOnContainer,
    Color? pocusPrimary,
    Color? pocusContainer,
    Color? pocusOnContainer,
    Color? alertePrimary,
    Color? alerteContainer,
    Color? alerteOnContainer,
  }) {
    return MedicalColors(
      medicamentPrimary: medicamentPrimary ?? this.medicamentPrimary,
      medicamentContainer: medicamentContainer ?? this.medicamentContainer,
      medicamentOnContainer: medicamentOnContainer ?? this.medicamentOnContainer,
      protocolPrimary: protocolPrimary ?? this.protocolPrimary,
      protocolContainer: protocolContainer ?? this.protocolContainer,
      protocolOnContainer: protocolOnContainer ?? this.protocolOnContainer,
      annuairePrimary: annuairePrimary ?? this.annuairePrimary,
      annuaireContainer: annuaireContainer ?? this.annuaireContainer,
      annuaireOnContainer: annuaireOnContainer ?? this.annuaireOnContainer,
      calculusPrimary: calculusPrimary ?? this.calculusPrimary,
      calculusContainer: calculusContainer ?? this.calculusContainer,
      calculusOnContainer: calculusOnContainer ?? this.calculusOnContainer,
      pocusPrimary: pocusPrimary ?? this.pocusPrimary,
      pocusContainer: pocusContainer ?? this.pocusContainer,
      pocusOnContainer: pocusOnContainer ?? this.pocusOnContainer,
      alertePrimary: alertePrimary ?? this.alertePrimary,
      alerteContainer: alerteContainer ?? this.alerteContainer,
      alerteOnContainer: alerteOnContainer ?? this.alerteOnContainer,
    );
  }

  @override
  MedicalColors lerp(ThemeExtension<MedicalColors>? other, double t) {
    if (other is! MedicalColors) {
      return this;
    }
    return MedicalColors(
      medicamentPrimary: Color.lerp(medicamentPrimary, other.medicamentPrimary, t)!,
      medicamentContainer: Color.lerp(medicamentContainer, other.medicamentContainer, t)!,
      medicamentOnContainer: Color.lerp(medicamentOnContainer, other.medicamentOnContainer, t)!,
      protocolPrimary: Color.lerp(protocolPrimary, other.protocolPrimary, t)!,
      protocolContainer: Color.lerp(protocolContainer, other.protocolContainer, t)!,
      protocolOnContainer: Color.lerp(protocolOnContainer, other.protocolOnContainer, t)!,
      annuairePrimary: Color.lerp(annuairePrimary, other.annuairePrimary, t)!,
      annuaireContainer: Color.lerp(annuaireContainer, other.annuaireContainer, t)!,
      annuaireOnContainer: Color.lerp(annuaireOnContainer, other.annuaireOnContainer, t)!,
      calculusPrimary: Color.lerp(calculusPrimary, other.calculusPrimary, t)!,
      calculusContainer: Color.lerp(calculusContainer, other.calculusContainer, t)!,
      calculusOnContainer: Color.lerp(calculusOnContainer, other.calculusOnContainer, t)!,
      pocusPrimary: Color.lerp(pocusPrimary, other.pocusPrimary, t)!,
      pocusContainer: Color.lerp(pocusContainer, other.pocusContainer, t)!,
      pocusOnContainer: Color.lerp(pocusOnContainer, other.pocusOnContainer, t)!,
      alertePrimary: Color.lerp(alertePrimary, other.alertePrimary, t)!,
      alerteContainer: Color.lerp(alerteContainer, other.alerteContainer, t)!,
      alerteOnContainer: Color.lerp(alerteOnContainer, other.alerteOnContainer, t)!,
    );
  }
}

class AppTheme {
  // -- PALETTE LIGHT --
  static const _lightMedicalColors = MedicalColors(
    medicamentPrimary: Color(0xFF1976D2),
    medicamentContainer: Color(0xFFBBDEFB),
    medicamentOnContainer: Color(0xFF0D47A1),
    
    protocolPrimary: Color(0xFFF57C00),
    protocolContainer: Color(0xFFFFE0B2),
    protocolOnContainer: Color(0xFFE65100),
    
    annuairePrimary: Color(0xFF388E3C),
    annuaireContainer: Color(0xFFC8E6C9),
    annuaireOnContainer: Color(0xFF1B5E20),
    
    calculusPrimary: Color(0xFF7B1FA2),
    calculusContainer: Color(0xFFE1BEE7),
    calculusOnContainer: Color(0xFF4A148C),

    // POCUS : Teal (Imagerie)
    pocusPrimary: Color(0xFF00796B),
    pocusContainer: Color(0xFFB2DFDB),
    pocusOnContainer: Color(0xFF004D40),
    
    alertePrimary: Color(0xFFD32F2F),
    alerteContainer: Color(0xFFFFCDD2),
    alerteOnContainer: Color(0xFFB71C1C),
  );

  // -- PALETTE DARK --
  static const _darkMedicalColors = MedicalColors(
    medicamentPrimary: Color(0xFF90CAF9),
    medicamentContainer: Color(0xFF1E3A5F),
    medicamentOnContainer: Color(0xFFE3F2FD),

    protocolPrimary: Color(0xFFFFCC80),
    protocolContainer: Color(0xFF5F421E),
    protocolOnContainer: Color(0xFFFFF3E0),

    annuairePrimary: Color(0xFFA5D6A7),
    annuaireContainer: Color(0xFF1E4521),
    annuaireOnContainer: Color(0xFFE8F5E9),

    calculusPrimary: Color(0xFFCE93D8),
    calculusContainer: Color(0xFF4A148C),
    calculusOnContainer: Color(0xFFF3E5F5),

    // POCUS Dark
    pocusPrimary: Color(0xFF80CBC4),
    pocusContainer: Color(0xFF004D40),
    pocusOnContainer: Color(0xFFE0F2F1),

    alertePrimary: Color(0xFFEF9A9A),
    alerteContainer: Color(0xFF5F1E1E),
    alerteOnContainer: Color(0xFFFFEBEE),
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      extensions: const [_lightMedicalColors],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF2C2C2C),
      ),
      extensions: const [_darkMedicalColors],
    );
  }
}

extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  MedicalColors get medicalColors => Theme.of(this).extension<MedicalColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}