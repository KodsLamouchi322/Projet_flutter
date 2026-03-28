import 'package:flutter/material.dart';

// ─── Palette moderne bleu / jaune / orange ────────────────────────────────────
class AppColors {
  // Bleu — primaire
  static const Color primary      = Color(0xFF1565C0); // bleu vif profond
  static const Color primaryLight = Color(0xFF1E88E5); // bleu clair
  static const Color primaryDark  = Color(0xFF0D47A1); // bleu nuit
  static const Color primarySoft  = Color(0xFFE3F2FD); // bleu très pâle (fond chips)

  // Orange — accent chaud
  static const Color accent       = Color(0xFFFF8F00); // orange doré
  static const Color accentLight  = Color(0xFFFFB300); // jaune-orange
  static const Color accentDark   = Color(0xFFE65100); // orange brûlé
  static const Color accentSoft   = Color(0xFFFFF8E1); // crème (fond chips)

  // Dégradés prédéfinis
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientWarm = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientHero = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Statuts
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error   = Color(0xFFC62828);
  static const Color errorLight  = Color(0xFFFFEBEE);
  static const Color info    = Color(0xFF1565C0);
  static const Color infoLight   = Color(0xFFE3F2FD);

  // Neutres — light mode
  static const Color background     = Color(0xFFF4F6FB);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4FF);
  static const Color textPrimary    = Color(0xFF0D1B2A);
  static const Color textSecondary  = Color(0xFF5C6B7A);
  static const Color divider        = Color(0xFFE0E7EF);
  static const Color border         = Color(0xFFCDD5E0);

  // Neutres — dark mode
  static const Color backgroundDark     = Color(0xFF0A0E1A);
  static const Color surfaceDark        = Color(0xFF111827);
  static const Color surfaceVariantDark = Color(0xFF1C2537);
  static const Color textPrimaryDark    = Color(0xFFF0F4FF);
  static const Color textSecondaryDark  = Color(0xFF8FA3B8);
  static const Color dividerDark        = Color(0xFF1E2D40);
}

// ─── Typographie ──────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
  );
}

// ─── Espacements / Tailles ────────────────────────────────────────────────────
class AppSizes {
  static const double paddingXS     = 4.0;
  static const double paddingSmall  = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge  = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radius        = 14.0;
  static const double radiusLarge   = 22.0;
  static const double radiusSmall   = 8.0;
  static const double radiusXL      = 28.0;

  // Compat aliases
  static const double borderRadius      = radius;
  static const double borderRadiusLarge = radiusLarge;
  static const double borderRadiusSmall = radiusSmall;

  static const double cardElevation  = 0.0;
  static const double iconSize       = 24.0;
  static const double iconSizeLarge  = 32.0;

  static const double livreCardHeight  = 200.0;
  static const double livreCardWidth   = 130.0;
  static const double couvertureHeight = 180.0;

  // Bottom nav height
  static const double bottomNavHeight = 64.0;
}

// ─── Constantes métier ────────────────────────────────────────────────────────
class AppConstants {
  static const int dureeEmpruntJours     = 21;
  static const int dureeReservationJours = 7;
  static const int maxEmpruntsSimultanes = 5;
  static const int maxProlongations      = 2;
  static const int dureeProlongationJours = 7;

  static const String colLivres        = 'livres';
  static const String colMembres       = 'membres';
  static const String colEmprunts      = 'emprunts';
  static const String colReservations  = 'reservations';
  static const String colEvenements    = 'evenements';
  static const String colMessages      = 'messages';
  static const String colConversations = 'conversations';
  static const String colForum         = 'forum';
  static const String colAnnonces      = 'annonces';

  static const List<String> genres = [
    'Roman', 'Policier', 'Science-Fiction', 'Fantasy', 'Biographie',
    'Histoire', 'Sciences', 'Jeunesse', 'Manga', 'BD',
    'Philosophie', 'Art', 'Cuisine', 'Sport', 'Voyage', 'Autre',
  ];

  static const String erreurReseau    = 'Erreur de connexion. Vérifiez votre internet.';
  static const String erreurInconnu   = 'Une erreur inattendue s\'est produite.';
  static const String erreurPermission = 'Vous n\'avez pas les permissions.';
  static const String modeHorsLigneCache =
      'Catalogue en cache (hors ligne ou erreur réseau). Certaines infos peuvent être anciennes.';
}

// ─── Thème ────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg      = isDark ? AppColors.backgroundDark     : AppColors.background;
    final surface = isDark ? AppColors.surfaceDark        : AppColors.surface;
    final surfVar = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final txtPri  = isDark ? AppColors.textPrimaryDark    : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark  : AppColors.textSecondary;
    final div     = isDark ? AppColors.dividerDark        : AppColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:          AppColors.primary,
        onPrimary:        Colors.white,
        primaryContainer: isDark ? AppColors.primaryDark : AppColors.primarySoft,
        onPrimaryContainer: isDark ? Colors.white : AppColors.primaryDark,
        secondary:        AppColors.accent,
        onSecondary:      Colors.white,
        secondaryContainer: isDark ? const Color(0xFF3D2800) : AppColors.accentSoft,
        onSecondaryContainer: isDark ? AppColors.accentLight : AppColors.accentDark,
        surface:          surface,
        onSurface:        txtPri,
        surfaceContainerHighest: surfVar,
        onSurfaceVariant: txtSec,
        error:            AppColors.error,
        onError:          Colors.white,
        outline:          div,
        shadow:           Colors.black,
      ),
      scaffoldBackgroundColor: bg,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Cards — flat avec légère ombre
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: TextStyle(color: txtSec, fontSize: 14),
        hintStyle: TextStyle(color: txtSec.withValues(alpha: 0.6), fontSize: 14),
        prefixIconColor: txtSec,
      ),

      // Boutons élevés
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Boutons outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(fontSize: 12, color: txtPri),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: div),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: txtSec,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: AppColors.accentLight,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        dividerColor: Colors.transparent,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
        elevation: 8,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}

// ─── Helpers visuels partagés ─────────────────────────────────────────────────
class AppUI {
  /// Ombre douce pour les cards
  static List<BoxShadow> get cardShadow => [
    const BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => cardShadow;

  /// Décoration card standard
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: const Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 0.5),
    ),
    boxShadow: softShadow,
  );

  /// Décoration card avec dégradé bleu
  static BoxDecoration gradientCard({double radius = AppSizes.radius}) => BoxDecoration(
    gradient: AppColors.gradientCard,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: cardShadow,
  );

  /// Badge pill coloré
  static Widget badge(String label, Color color, {double fontSize = 11}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: fontSize, fontWeight: FontWeight.w700,
      )),
    );
}

class AppInputDecoration {
  static InputDecoration standard({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
