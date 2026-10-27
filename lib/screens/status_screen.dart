import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../widgets/demo_sheet.dart';
import '../widgets/emergency_guide_sheet.dart';
import '../widgets/mesh_logo.dart';
import 'logs_screen.dart';

/// ============================================================================
/// PANTALLA: ESTADO DEL DISPOSITIVO (TELEMETRÍA & HARDWARE)
/// ============================================================================
/// Estándar: Ultra-minimalista, limpio y empresarial (iOS Settings / Dashboard).
/// - CERO widget Card de Material Design ni sombras pesadas.
/// - Batería Elegante: Porcentaje en fuente delgada (w300) y color #183B59. Barra de progreso de máx 4px.
/// - Señal de Radio LoRa: 3 métricas en una sola fila (Row con Expanded) divididas solo por VerticalDivider.
/// - Lista de Información (Nodo): Filas limpias (spaceBetween), título en #757575 y valor en #183B59 (w500).
/// ============================================================================

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandPrimary = Color(0xFF1F74BF);
    const Color brandDark = Color(0xFF183B59);
    const Color textMuted = Color(0xFF757575);
    const Color onlineGreen = Color(0xFF10B981);
    const Color redAlert = Color(0xFFE53935);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MeshProvider>();
    final status = provider.deviceStatus;
    final battery = status.batteryPercent;
    final isBleConnected = status.isBleConnected;

    // Bloqueo estricto a Modo Claro para emergencias (AAA Contrast)
    const Color bgColor = Color(0xFFF2F2F2);
    const Color sectionBg = Color(0xFFFFFFFF);
    const Color dividerColor = Color(0x1F9E9E9E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: brandDark,
        title: Row(
          children: [
            const MeshLogo(
              height: 28,
              fit: BoxFit.contain,
              borderRadius: 6,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Estado del Dispositivo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: brandDark,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isBleConnected ? onlineGreen : textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          isBleConnected
                              ? '${status.connectedDeviceName.isNotEmpty ? status.connectedDeviceName : "WisBlock"} · BLE Conectado'
                              : 'WisBlock RAK4630 · Desconectado',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Modo Demo',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDemoNavigationModal(context);
                },
                icon: const Icon(Icons.bolt_rounded, size: 20, color: onlineGreen),
              ),
              IconButton(
                tooltip: 'Sincronizar',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Actualizando telemetría y estado de la radio...'),
                      duration: Duration(milliseconds: 900),
                      backgroundColor: brandDark,
                    ),
                  );
                  await provider.refreshAllData();
                },
                icon: const Icon(Icons.sync_rounded, size: 20, color: brandDark),
              ),
              IconButton(
                tooltip: 'Consola de Logs',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogsScreen()),
                  );
                },
                icon: const Icon(Icons.terminal_rounded, size: 20, color: brandDark),
              ),
              const Gap(16), // Margen mínimo de 16px horizontal en el extremo derecho
            ],
          ),
        ],
        // ====================================================================
        // SECCIÓN INDEPENDIENTE: CONTROL DE ACCESIBILIDAD (A- / A+)
        // Tarjeta ultra-minimalista, fondo #F2F2F2, sin sombras pesadas
        // ====================================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2), // Fondo #F2F2F2 ultra-minimalista
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0x1F183B59),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.decreaseTextScale();
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        height: 42,
                        alignment: Alignment.center,
                        child: Text(
                          'A-',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: brandDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0x1F183B59),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_size_rounded, size: 15, color: brandDark),
                        const Gap(6),
                        Text(
                          'Texto: ${(provider.textScaleFactor * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: brandDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0x1F183B59),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.increaseTextScale();
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        height: 42,
                        alignment: Alignment.center,
                        child: Text(
                          'A+',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: brandDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAllData(),
        color: brandPrimary,
        backgroundColor: sectionBg,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ================================================================
            // 1. SECCIÓN BATERÍA ELEGANTE (FUENTE DELGADA W300, BARRA 4PX)
            // ================================================================
            _buildSectionContainer(
              bgColor: sectionBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Batería de la Radio',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        status.voltage > 0
                            ? '${status.voltage.toStringAsFixed(2)} V'
                            : (battery > 0 ? '$battery%' : '--'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (battery > 20) ? onlineGreen : redAlert,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Porcentaje grande con fuente delgada (FontWeight.w300) y color #183B59
                      Text(
                        battery > 0
                            ? '$battery%'
                            : (status.voltage > 0 ? '${status.voltage.toStringAsFixed(2)}V' : '--'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 38,
                          fontWeight: FontWeight.w300, // Fuente delgada elegante
                          color: isDark ? Colors.white : brandDark, // #183B59
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          status.batteryRemainingEstimated,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  // Barra de progreso reducida a máximo 4px de alto con bordes redondeados
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: battery > 0
                          ? (battery / 100).clamp(0.0, 1.0)
                          : (status.voltage > 0
                              ? ((status.voltage - 3.20) / (4.20 - 3.20)).clamp(0.0, 1.0)
                              : 0.0),
                      minHeight: 4, // Máximo 4px de alto
                      backgroundColor: isDark ? const Color(0xFF183B59) : const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        battery > 20 ? onlineGreen : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ================================================================
            // 2. SEÑAL DE RADIO LORA (CERO TARJETAS ANIDADAS, EXPANDED + VERTICALDIVIDER)
            // ================================================================
            _buildSectionContainer(
              bgColor: sectionBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Señal de Radio LoRa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      Text(
                        '${status.frequencyMhz.toStringAsFixed(0)} MHz · SUBTEL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // Fila única con Expanded para cada dato, divididos solo por VerticalDivider
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildCleanMetricItem(
                          label: 'Señal LoRa',
                          value: status.signalDbm != 0 ? '${status.signalDbm} dBm' : '--',
                          brandDark: brandDark,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: dividerColor,
                        ),
                        _buildCleanMetricItem(
                          label: 'Nodos Malla',
                          value: '${status.activeNodesCount}',
                          brandDark: brandDark,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: dividerColor,
                        ),
                        _buildCleanMetricItem(
                          label: 'Mensajes',
                          value: '${status.totalMessagesTransmitted}',
                          brandDark: brandDark,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ================================================================
            // 3. INFORMACIÓN DEL NODO (FILAS LIMPIAS SOBRE FONDO BLANCO PURO)
            // ================================================================
            _buildSectionContainer(
              bgColor: sectionBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Nodo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const Gap(10),
                  _buildCleanInfoRow(
                    title: 'Modelo Hardware',
                    value: status.hardwareModel,
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  _buildCleanInfoRow(
                    title: 'ID del Nodo (Hex)',
                    value: status.nodeId,
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  _buildCleanInfoRow(
                    title: 'Número de Nodo',
                    value: status.myNodeNum != 0 ? '${status.myNodeNum}' : '--',
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  _buildCleanInfoRow(
                    title: 'Versión Firmware',
                    value: status.firmwareVersion.isNotEmpty ? status.firmwareVersion : '--',
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  _buildCleanInfoRow(
                    title: 'Nombre de Usuario',
                    value: provider.userName,
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                    trailing: GestureDetector(
                      onTap: () => _showEditNameDialog(context),
                      child: Text(
                        'Editar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandPrimary,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  _buildCleanInfoRow(
                    title: 'Dispositivo BLE',
                    value: status.connectedDeviceName.isNotEmpty
                        ? status.connectedDeviceName
                        : 'Sin conexión',
                    brandDark: brandDark,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ================================================================
            // 4. UBICACIÓN GPS Y FLASH DE LA RADIO
            // ================================================================
            _buildSectionContainer(
              bgColor: sectionBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubicación en Memoria Flash',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      if (provider.currentGpsPosition != null)
                        Text(
                          'GPS Fijado',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: onlineGreen,
                          ),
                        ),
                    ],
                  ),
                  const Gap(12),
                  if (provider.currentGpsPosition != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat: ${provider.currentGpsPosition!.latitude.toStringAsFixed(5)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : brandDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Lon: ${provider.currentGpsPosition!.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                  ],
                  Text(
                    'Graba las coordenadas del teléfono en la memoria Flash del WisBlock para funcionar desconectado.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                      height: 1.35,
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (isBleConnected && !provider.isSavingFixedPosition)
                              ? () async {
                                  HapticFeedback.lightImpact();
                                  final ok = await provider.saveCurrentLocationToRadioFlash();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? '✅ Ubicación grabada en memoria Flash.'
                                            : '❌ Error al grabar ubicación.'),
                                        backgroundColor: brandDark,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x331F74BF), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            provider.isSavingFixedPosition
                                ? 'Grabando...'
                                : 'Fijar Ubicación en Antena',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: brandPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (provider.lastFixedPositionSavedAt != null && isBleConnected) ...[
                        const Gap(8),
                        IconButton(
                          tooltip: 'Borrar posición fija',
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await provider.clearLocationFromRadioFlash();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Posición fija eliminada de Flash.'),
                                  backgroundColor: brandDark,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: redAlert),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ================================================================
            // 5. ACCESIBILIDAD Y ESCALA DE TEXTO (A11Y & CRISIS VISIBILITY)
            // ================================================================
            _buildSectionContainer(
              bgColor: sectionBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Accesibilidad y Escala de Texto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x3310B981)),
                        ),
                        child: Text(
                          'AAA Contraste',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),

                  // Controles principales A- y A+ con indicador numérico
                  Row(
                    children: [
                      // Botón A- accesible (área táctil >= 48x48dp)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            provider.decreaseTextScale();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x1F183B59)),
                            ),
                            child: Center(
                              child: Text(
                                'A-',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: brandDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Gap(10),

                      // Lectura de Porcentaje y Estado
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Escala:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                              Text(
                                '${(provider.textScaleFactor * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: brandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(10),

                      // Botón A+ accesible (área táctil >= 48x48dp)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            provider.increaseTextScale();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x1F183B59)),
                            ),
                            child: Center(
                              child: Text(
                                'A+',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: brandDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),

                  // Presets rápidos (100% Normal, 130% Grande, 160% Muy Grande, 200% Emergencia)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildScalePresetChip(
                        label: '100% Normal',
                        targetScale: 1.0,
                        currentScale: provider.textScaleFactor,
                        brandDark: brandDark,
                        onTap: () => provider.setTextScaleFactor(1.0),
                      ),
                      _buildScalePresetChip(
                        label: '130% Grande',
                        targetScale: 1.3,
                        currentScale: provider.textScaleFactor,
                        brandDark: brandDark,
                        onTap: () => provider.setTextScaleFactor(1.3),
                      ),
                      _buildScalePresetChip(
                        label: '160% Muy Grande',
                        targetScale: 1.6,
                        currentScale: provider.textScaleFactor,
                        brandDark: brandDark,
                        onTap: () => provider.setTextScaleFactor(1.6),
                      ),
                      _buildScalePresetChip(
                        label: '200% Emergencia',
                        targetScale: 2.0,
                        currentScale: provider.textScaleFactor,
                        brandDark: brandDark,
                        onTap: () => provider.setTextScaleFactor(2.0),
                      ),
                    ],
                  ),
                  const Gap(14),

                  // Muestra en vivo de legibilidad
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x18183B59)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VISTA PREVIA EN VIVO:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: brandPrimary,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Evacuación preventiva a zona segura y mantener antena LoRa encendida.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: brandDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ================================================================
            // 6. ACCIONES DE GESTIÓN Y BOTONES LIMPIOS
            // ================================================================
            if (isBleConnected)
              OutlinedButton(
                onPressed: () => _showDisconnectDialog(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x40E53935), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Desconectar Antena WisBlock',
                  style: GoogleFonts.plusJakartaSans(
                    color: redAlert,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => provider.startPairingScan(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Vincular / Conectar Antena',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),

            const Gap(12),

            // Botón Guía de Emergencia plano
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                EmergencyGuideSheet.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: redAlert,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Guía de Emergencia y Protocolos',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  /// Contenedor limpio sobre fondo continuo (CERO Card, CERO sombras pesadas)
  Widget _buildSectionContainer({
    required Widget child,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1F9E9E9E), // Borde tenue
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Dato métrico individual para la fila de Señal LoRa (sin bordes anidados)
  Widget _buildCleanMetricItem({
    required String label,
    required String value,
    required Color brandDark,
    required Color textMuted,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : brandDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de información limpia (Título a la izquierda en #757575, valor a la derecha en #183B59 w500)
  /// Resiliente a escalas de texto de hasta 200% sin causar overflow
  Widget _buildCleanInfoRow({
    required String title,
    required String value,
    required Color brandDark,
    required Color textMuted,
    required bool isDark,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textMuted, // #757575
              ),
              softWrap: true,
            ),
          ),
          const Gap(12),
          Flexible(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500, // FontWeight.w500
                      color: brandDark, // #183B59
                    ),
                    softWrap: true,
                  ),
                ),
                if (trailing != null) ...[
                  const Gap(8),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip interactivo para selección rápida de factor de escala de texto
  Widget _buildScalePresetChip({
    required String label,
    required double targetScale,
    required double currentScale,
    required Color brandDark,
    required VoidCallback onTap,
  }) {
    final isSelected = (currentScale - targetScale).abs() < 0.08;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF183B59) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF183B59) : const Color(0x1F183B59),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : brandDark,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final provider = context.read<MeshProvider>();
    const Color brandDark = Color(0xFF183B59);
    const Color brandPrimary = Color(0xFF1F74BF);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF122C43) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nombre del Nodo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : brandDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identificador visible para los demás nodos de la malla:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF757575),
              ),
            ),
            const Gap(14),
            TextField(
              controller: textController,
              autofocus: true,
              maxLength: 30,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : brandDark,
              ),
              decoration: InputDecoration(
                hintText: 'Ej. Juan P. - Central',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = textController.text.trim();
              Navigator.pop(ctx);
              if (newName.isNotEmpty) {
                await provider.updateUserName(newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nombre de nodo actualizado a "$newName"'),
                      backgroundColor: brandDark,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    const Color brandDark = Color(0xFF183B59);
    const Color redAlert = Color(0xFFE53935);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF122C43) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desconectar Antena',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : brandDark,
          ),
        ),
        content: Text(
          '¿Deseas desconectar el enlace Bluetooth con la antena WisBlock RAK4630?\n\nDejarás de recibir telemetría y mensajes de la malla hasta volver a conectarla.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF757575),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<MeshProvider>();
              await provider.disconnectRadio();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Antena WisBlock desconectada.'),
                    backgroundColor: brandDark,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}
