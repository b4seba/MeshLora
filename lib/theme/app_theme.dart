import 'package:flutter/material.dart';
import 'theme.dart';

export 'theme.dart';

/// Compatibilidad hacia atrás y puente con el nuevo sistema de diseño corporativo.
class AppTheme {
  // Paleta Oficial 'Alerta Mesh'
  static const Color primaryBlue = AppPalette.primaryBlue; // #1F74BF
  static const Color darkNavy = AppPalette.darkNavy; // #183B59
  static const Color mediumBlue = AppPalette.mediumBlue; // #3D9DD9
  static const Color skyBlue = AppPalette.skyBlue; // #48B0D9
  static const Color lightGray = AppPalette.lightGray; // #F2F2F2

  // Alias para mantener compatibilidad con pantallas existentes
  static const Color obsidian = AppPalette.darkNavy;
  static const Color obsidianBg = AppPalette.darkNavy;
  static const Color obsidianSurface = AppPalette.darkSurface;
  static const Color obsidianCard = AppPalette.darkSurface;
  static const Color obsidianElevated = AppPalette.darkSurfaceElevated;
  static const Color obsidianBorder = AppPalette.darkBorder;

  static const Color electricBlue = AppPalette.primaryBlue;
  static const Color electricBlueDark = Color(0xFF165993);
  static const Color electricBlueLight = Color(0xFFE5F1FA);

  static const Color onlineGreen = AppPalette.onlineGreen;
  static const Color onlineGreenLight = AppPalette.onlineGreenLight;

  static const Color redAlert = AppPalette.emergencyRed;
  static const Color redAlertDark = AppPalette.emergencyRedDark;
  static const Color redAlertLight = AppPalette.emergencyRedLight;

  static const Color warningAmber = AppPalette.warningAmber;
  static const Color warningAmberLight = AppPalette.warningAmberLight;

  static const Color bgLight = AppPalette.lightGray; // #F2F2F2
  static const Color cardBg = AppPalette.lightSurface;
  static const Color surfaceLight = AppPalette.lightSurface;

  static const Color textDark = AppPalette.darkNavy; // #183B59 para títulos y textos en modo claro
  static const Color textMuted = AppPalette.lightTextMuted;
  static const Color textLight = AppPalette.lightGray;
  static const Color textSubtle = AppPalette.lightTextSubtle;

  // Dark Mode Text & Surface Helpers
  static const Color textPrimaryDark = AppPalette.lightGray; // #F2F2F2
  static const Color textMutedDark = AppPalette.darkTextMuted;
  static const Color textSubtleDark = AppPalette.darkTextSubtle;
  static const Color borderDark = AppPalette.darkBorder;

  static const Color borderSubtle = AppPalette.lightBorder;
  static const Color borderSubtleDark = AppPalette.darkBorderSubtle;

  // Alias adicionales
  static const Color navy = AppPalette.darkNavy;
  static const Color navyLight = AppPalette.darkSurface;
  static const Color navyDark = AppPalette.darkNavy;
  static const Color lime = AppPalette.onlineGreen;
  static const Color limeLight = AppPalette.onlineGreenLight;
  static const Color orange = AppPalette.primaryBlue;
  static const Color orangeLight = electricBlueLight;

  static ThemeData get theme => lightTheme;
  static ThemeData get lightTheme => AlertaMeshTheme.light;
  static ThemeData get darkTheme => AlertaMeshTheme.dark;
}
