import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// SISTEMA DE DISEÑO VISUAL CORPORATIVO: 'ALERTA MESH'
/// ============================================================================
/// Paleta Oficial:
/// - #1F74BF: Azul Primario (Acciones principales, acentos destacados)
/// - #183B59: Azul Oscuro (Títulos y textos en claro; Fondo principal en oscuro)
/// - #3D9DD9: Azul Medio (Acentos luminosos, estados interactivos y bordes)
/// - #48B0D9: Celeste (Acentos luminosos complementarios y telemetría)
/// - #F2F2F2: Gris Claro (Scaffold en modo claro; Textos y alto contraste en oscuro)
/// ============================================================================

class AppPalette {
  AppPalette._();

  // Colores corporativos base
  static const Color primaryBlue = Color(0xFF1F74BF);
  static const Color darkNavy = Color(0xFF183B59);
  static const Color mediumBlue = Color(0xFF3D9DD9);
  static const Color skyBlue = Color(0xFF48B0D9);
  static const Color lightGray = Color(0xFFF2F2F2);

  // Derivados tonales para profundidad y superficies (Modo Claro)
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0x1F183B59); // 12% opacidad de Azul Oscuro
  static const Color lightBorderSubtle = Color(0x12183B59);
  static const Color lightTextMuted = Color(0xFF536E82);
  static const Color lightTextSubtle = Color(0xFF7E97AA);

  // Derivados tonales para profundidad y superficies (Modo Oscuro)
  static const Color darkSurface = Color(0xFF122C43); // Superficie elevada sobre #183B59
  static const Color darkSurfaceElevated = Color(0xFF1B4060);
  static const Color darkBorder = Color(0x3348B0D9); // Acento celeste sutil
  static const Color darkBorderSubtle = Color(0x1F3D9DD9);
  static const Color darkTextMuted = Color(0xFFB0C6D8);
  static const Color darkTextSubtle = Color(0xFF7E9BB3);

  // Semántica de emergencia y estado
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyRedLight = Color(0xFFFFEBEE);
  static const Color emergencyRedDark = Color(0xFFB71C1C);
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color onlineGreenLight = Color(0xFFE8F5E9);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberLight = Color(0xFFFFF8E1);
}

/// ============================================================================
/// TOKENS Y EXTENSIÓN PERSONALIZADA DE TEMA (ThemeExtension)
/// ============================================================================
@immutable
class AlertaMeshTokens extends ThemeExtension<AlertaMeshTokens> {
  final Color bubbleMine;
  final Color bubbleMineText;
  final Color bubbleOther;
  final Color bubbleOtherText;
  final Color bubbleOtherBorder;
  final Color urgentBadgeBg;
  final Color urgentBadgeText;
  final Color headerSurface;
  final Color headerBorder;
  final Color actionButtonBg;
  final Color actionButtonFg;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> bubbleShadow;

  const AlertaMeshTokens({
    required this.bubbleMine,
    required this.bubbleMineText,
    required this.bubbleOther,
    required this.bubbleOtherText,
    required this.bubbleOtherBorder,
    required this.urgentBadgeBg,
    required this.urgentBadgeText,
    required this.headerSurface,
    required this.headerBorder,
    required this.actionButtonBg,
    required this.actionButtonFg,
    required this.cardShadow,
    required this.bubbleShadow,
  });

  @override
  AlertaMeshTokens copyWith({
    Color? bubbleMine,
    Color? bubbleMineText,
    Color? bubbleOther,
    Color? bubbleOtherText,
    Color? bubbleOtherBorder,
    Color? urgentBadgeBg,
    Color? urgentBadgeText,
    Color? headerSurface,
    Color? headerBorder,
    Color? actionButtonBg,
    Color? actionButtonFg,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? bubbleShadow,
  }) {
    return AlertaMeshTokens(
      bubbleMine: bubbleMine ?? this.bubbleMine,
      bubbleMineText: bubbleMineText ?? this.bubbleMineText,
      bubbleOther: bubbleOther ?? this.bubbleOther,
      bubbleOtherText: bubbleOtherText ?? this.bubbleOtherText,
      bubbleOtherBorder: bubbleOtherBorder ?? this.bubbleOtherBorder,
      urgentBadgeBg: urgentBadgeBg ?? this.urgentBadgeBg,
      urgentBadgeText: urgentBadgeText ?? this.urgentBadgeText,
      headerSurface: headerSurface ?? this.headerSurface,
      headerBorder: headerBorder ?? this.headerBorder,
      actionButtonBg: actionButtonBg ?? this.actionButtonBg,
      actionButtonFg: actionButtonFg ?? this.actionButtonFg,
      cardShadow: cardShadow ?? this.cardShadow,
      bubbleShadow: bubbleShadow ?? this.bubbleShadow,
    );
  }

  @override
  AlertaMeshTokens lerp(ThemeExtension<AlertaMeshTokens>? other, double t) {
    if (other is! AlertaMeshTokens) return this;
    return AlertaMeshTokens(
      bubbleMine: Color.lerp(bubbleMine, other.bubbleMine, t)!,
      bubbleMineText: Color.lerp(bubbleMineText, other.bubbleMineText, t)!,
      bubbleOther: Color.lerp(bubbleOther, other.bubbleOther, t)!,
      bubbleOtherText: Color.lerp(bubbleOtherText, other.bubbleOtherText, t)!,
      bubbleOtherBorder: Color.lerp(bubbleOtherBorder, other.bubbleOtherBorder, t)!,
      urgentBadgeBg: Color.lerp(urgentBadgeBg, other.urgentBadgeBg, t)!,
      urgentBadgeText: Color.lerp(urgentBadgeText, other.urgentBadgeText, t)!,
      headerSurface: Color.lerp(headerSurface, other.headerSurface, t)!,
      headerBorder: Color.lerp(headerBorder, other.headerBorder, t)!,
      actionButtonBg: Color.lerp(actionButtonBg, other.actionButtonBg, t)!,
      actionButtonFg: Color.lerp(actionButtonFg, other.actionButtonFg, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? cardShadow,
      bubbleShadow: BoxShadow.lerpList(bubbleShadow, other.bubbleShadow, t) ?? bubbleShadow,
    );
  }

  static const light = AlertaMeshTokens(
    bubbleMine: AppPalette.primaryBlue,
    bubbleMineText: Colors.white,
    bubbleOther: Colors.white,
    bubbleOtherText: AppPalette.darkNavy,
    bubbleOtherBorder: AppPalette.lightBorder,
    urgentBadgeBg: AppPalette.emergencyRedLight,
    urgentBadgeText: AppPalette.emergencyRedDark,
    headerSurface: Colors.white,
    headerBorder: AppPalette.lightBorderSubtle,
    actionButtonBg: AppPalette.lightGray,
    actionButtonFg: AppPalette.darkNavy,
    cardShadow: [
      BoxShadow(
        color: Color(0x0F183B59),
        blurRadius: 12,
        offset: Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
    bubbleShadow: [
      BoxShadow(
        color: Color(0x0A183B59),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const dark = AlertaMeshTokens(
    bubbleMine: AppPalette.primaryBlue,
    bubbleMineText: Colors.white,
    bubbleOther: AppPalette.darkSurface,
    bubbleOtherText: AppPalette.lightGray,
    bubbleOtherBorder: AppPalette.darkBorder,
    urgentBadgeBg: Color(0x33E53935),
    urgentBadgeText: Color(0xFFFF8A80),
    headerSurface: AppPalette.darkNavy,
    headerBorder: AppPalette.darkBorderSubtle,
    actionButtonBg: AppPalette.darkSurfaceElevated,
    actionButtonFg: AppPalette.lightGray,
    cardShadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 14,
        offset: Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
    bubbleShadow: [
      BoxShadow(
        color: Color(0x28000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
}

/// ============================================================================
/// CONFIGURACIÓN GLOBAL DE TEMAS: ALERTA MESH
/// ============================================================================
class AlertaMeshTheme {
  AlertaMeshTheme._();

  // Constantes de diseño senior
  static const double minTouchTarget = 48.0; // Estándar de accesibilidad y emergencias
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusDefault = 14.0;
  static const double radiusLarge = 16.0;

  /// Tipografía con jerarquía limpia basada en Plus Jakarta Sans
  static TextTheme _buildTextTheme({required Color titleColor, required Color bodyColor, required Color mutedColor}) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: titleColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: titleColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: titleColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: titleColor,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: bodyColor,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        height: 1.35,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// TEMA CLARO (Default)
  /// Reglas:
  /// - scaffoldBackgroundColor: #F2F2F2
  /// - primary: #1F74BF (botones y acciones)
  /// - títulos y alto contraste: #183B59
  /// --------------------------------------------------------------------------
  static ThemeData get light {
    final textTheme = _buildTextTheme(
      titleColor: AppPalette.darkNavy,
      bodyColor: AppPalette.darkNavy,
      mutedColor: AppPalette.lightTextMuted,
    );

    const colorScheme = ColorScheme.light(
      primary: AppPalette.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E9F8),
      onPrimaryContainer: AppPalette.darkNavy,
      secondary: AppPalette.mediumBlue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE2F1FB),
      onSecondaryContainer: AppPalette.darkNavy,
      tertiary: AppPalette.skyBlue,
      onTertiary: AppPalette.darkNavy,
      surface: Colors.white,
      onSurface: AppPalette.darkNavy,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFAFAFA),
      surfaceContainer: Color(0xFFF7F7F7),
      surfaceContainerHigh: Color(0xFFEFEFEF),
      surfaceContainerHighest: Color(0xFFE6E6E6),
      outline: AppPalette.lightBorder,
      outlineVariant: AppPalette.lightBorderSubtle,
      error: AppPalette.emergencyRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.lightGray,
      textTheme: textTheme,
      extensions: const [AlertaMeshTokens.light],

      // Cabecera / AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.darkNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: AppPalette.darkNavy, size: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Botones Elevados (Área táctil mínima 48x48)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          backgroundColor: AppPalette.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Botones Contorneados (Área táctil mínima 48x48)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.darkNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppPalette.lightBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones de Texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Botones de Íconos
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.darkNavy,
          highlightColor: AppPalette.primaryBlue.withAlpha(25),
        ),
      ),

      // Tarjetas (Bordes consistentes 14-16px y sin sombras agresivas)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: AppPalette.lightBorder, width: 1),
        ),
      ),

      // Campos de Entrada (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.lightTextSubtle,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.emergencyRed, width: 1.2),
        ),
      ),

      // Divisores sutiles
      dividerTheme: const DividerThemeData(
        color: AppPalette.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),

      // Diálogos modales
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.darkNavy,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppPalette.lightGray,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// TEMA OSCURO
  /// Reglas:
  /// - scaffoldBackgroundColor: #183B59 (Fondo principal)
  /// - textos: #F2F2F2
  /// - acentos luminosos: #3D9DD9 y #48B0D9 para legibilidad máxima
  /// --------------------------------------------------------------------------
  static ThemeData get dark {
    final textTheme = _buildTextTheme(
      titleColor: AppPalette.lightGray,
      bodyColor: AppPalette.lightGray,
      mutedColor: AppPalette.darkTextMuted,
    );

    const colorScheme = ColorScheme.dark(
      primary: AppPalette.mediumBlue, // Acento luminoso principal
      onPrimary: AppPalette.darkNavy,
      primaryContainer: Color(0xFF1E4C73),
      onPrimaryContainer: Colors.white,
      secondary: AppPalette.skyBlue, // Segundo acento luminoso
      onSecondary: AppPalette.darkNavy,
      secondaryContainer: Color(0xFF194668),
      onSecondaryContainer: Colors.white,
      tertiary: AppPalette.primaryBlue,
      onTertiary: Colors.white,
      surface: AppPalette.darkSurface, // Superficie distinguida para tarjetas
      onSurface: AppPalette.lightGray,
      surfaceContainerLowest: AppPalette.darkNavy,
      surfaceContainerLow: Color(0xFF0F263B),
      surfaceContainer: AppPalette.darkSurface,
      surfaceContainerHigh: AppPalette.darkSurfaceElevated,
      surfaceContainerHighest: Color(0xFF235178),
      outline: AppPalette.darkBorder,
      outlineVariant: AppPalette.darkBorderSubtle,
      error: Color(0xFFFF5252),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.darkNavy,
      textTheme: textTheme,
      extensions: const [AlertaMeshTokens.dark],

      // Cabecera / AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.darkNavy,
        foregroundColor: AppPalette.lightGray,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: AppPalette.lightGray, size: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppPalette.darkNavy,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Botones Elevados (Área táctil mínima 48x48)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          backgroundColor: AppPalette.mediumBlue,
          foregroundColor: AppPalette.darkNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Botones Contorneados (Área táctil mínima 48x48)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.lightGray,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppPalette.darkBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones de Texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.skyBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Botones de Íconos
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: AppPalette.lightGray,
          highlightColor: AppPalette.skyBlue.withAlpha(35),
        ),
      ),

      // Tarjetas (Bordes consistentes 14-16px con acento de luminosidad)
      cardTheme: CardThemeData(
        color: AppPalette.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: AppPalette.darkBorder, width: 1),
        ),
      ),

      // Campos de Entrada (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.darkTextSubtle,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: AppPalette.skyBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
        ),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppPalette.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),

      // Diálogos modales
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.darkSurfaceElevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppPalette.lightGray,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Helper extension para acceder rápidamente a los tokens personalizados
extension AlertaMeshThemeContext on BuildContext {
  AlertaMeshTokens get tokens =>
      Theme.of(this).extension<AlertaMeshTokens>() ??
      (Theme.of(this).brightness == Brightness.dark ? AlertaMeshTokens.dark : AlertaMeshTokens.light);

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
