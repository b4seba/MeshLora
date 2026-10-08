import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/emergency_guide_sheet.dart';
import '../widgets/mesh_logo.dart';
import 'logs_screen.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final status = provider.deviceStatus;
    final battery = status.batteryPercent;
    final isBleConnected = status.isBleConnected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: isDark ? AppTheme.obsidian : Colors.white,
        title: Row(
          children: [
            const MeshLogo(
              height: 38,
              fit: BoxFit.contain,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Estado del Dispositivo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                    ),
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isBleConnected ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                          shape: BoxShape.circle,
                          boxShadow: isBleConnected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.onlineGreen.withAlpha(100),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const Gap(6),
                      Flexible(
                        child: Text(
                          isBleConnected
                              ? '${status.connectedDeviceName.isNotEmpty ? status.connectedDeviceName : "WisBlock RAK4630"} · BLE Activo'
                              : 'WisBlock RAK4630 · Desconectado',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isBleConnected ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                          ),
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
          Tooltip(
            message: 'Sincronizar Telemetría',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Actualizando telemetría y estado de la radio...'),
                      duration: Duration(milliseconds: 900),
                      backgroundColor: AppTheme.obsidian,
                    ),
                  );
                  await provider.refreshAllData();
                },
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
          const Gap(6),
          Tooltip(
            message: 'Consola de Logs',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
          const Gap(14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppTheme.obsidianBorder : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAllData(),
        color: AppTheme.electricBlue,
        backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Tarjeta de Batería de la Radio
            _buildCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.battery_charging_full_rounded,
                              color: AppTheme.onlineGreen,
                              size: 20,
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'Batería de la Radio',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (battery > 20)
                              ? (isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight)
                              : (isDark ? AppTheme.redAlert.withAlpha(40) : AppTheme.redAlertLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.voltage > 0
                              ? '${status.voltage.toStringAsFixed(2)} V'
                              : (battery > 0 ? '$battery%' : '--'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: (battery > 20) ? AppTheme.onlineGreen : AppTheme.redAlert,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        battery > 0 ? '$battery%' : (status.voltage > 0 ? '${status.voltage.toStringAsFixed(2)}V' : '--'),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textDark,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          status.batteryRemainingEstimated,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: battery > 0
                          ? (battery / 100).clamp(0.0, 1.0)
                          : (status.voltage > 0 ? ((status.voltage - 3.20) / (4.20 - 3.20)).clamp(0.0, 1.0) : 0.0),
                      minHeight: 8,
                      backgroundColor: isDark ? AppTheme.obsidianSurface : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        battery > 20 ? AppTheme.onlineGreen : AppTheme.warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0),

            const Gap(12),

            // 2. Tarjeta de Señal de Radio LoRa
            _buildCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sensors_rounded,
                              color: AppTheme.electricBlue,
                              size: 20,
                            ),
                          ),
                          const Gap(10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Señal de Radio LoRa',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '${status.frequencyMhz.toStringAsFixed(0)} MHz (SUBTEL Chile)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBleConnected
                              ? (isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight)
                              : (isDark ? AppTheme.obsidianSurface : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isBleConnected ? AppTheme.onlineGreen : AppTheme.textSubtle,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              isBleConnected ? 'Enlace Activo' : 'Desconectado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isBleConnected ? AppTheme.onlineGreen : AppTheme.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      _buildMetricBox(
                        context: context,
                        label: 'Señal LoRa',
                        value: status.signalDbm != 0 ? '${status.signalDbm} dBm' : '--',
                        icon: Icons.signal_cellular_alt_rounded,
                      ),
                      const Gap(8),
                      _buildMetricBox(
                        context: context,
                        label: 'Nodos Malla',
                        value: '${status.activeNodesCount}',
                        icon: Icons.people_outline_rounded,
                      ),
                      const Gap(8),
                      _buildMetricBox(
                        context: context,
                        label: 'Mensajes',
                        value: '${status.totalMessagesTransmitted}',
                        icon: Icons.send_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 200.ms).slideY(begin: 0.05, end: 0),

            const Gap(12),

            // 3. Tarjeta de Información del Nodo
            _buildCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Nodo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const Gap(12),
                  _buildInfoRow(context, 'Modelo Hardware', status.hardwareModel),
                  _buildInfoRow(context, 'ID del Nodo (Hex)', status.nodeId),
                  _buildInfoRow(context, 'Número de Nodo', status.myNodeNum != 0 ? '${status.myNodeNum}' : '--'),
                  _buildInfoRow(context, 'Versión Firmware', status.firmwareVersion.isNotEmpty ? status.firmwareVersion : '--'),
                  _buildInfoRow(
                    context,
                    'Nombre de Usuario',
                    provider.userName,
                    onTap: () => _showEditNameDialog(context),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.electricBlue,
                        ),
                      ),
                    ),
                  ),
                  _buildInfoRow(
                    context,
                    'Dispositivo BLE',
                    status.connectedDeviceName.isNotEmpty ? status.connectedDeviceName : 'Sin conexión',
                    isLast: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 200.ms).slideY(begin: 0.05, end: 0),

            const Gap(12),

            // 4. Tarjeta de Ubicación GPS y Memoria Flash de la Radio
            _buildCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.electricBlue,
                              size: 20,
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'Ubicación GPS & Flash',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (provider.currentGpsPosition != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GPS Teléfono',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onlineGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(14),
                  if (provider.currentGpsPosition != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitud',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  provider.currentGpsPosition!.latitude.toStringAsFixed(6),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Longitud',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  provider.currentGpsPosition!.longitude.toStringAsFixed(6),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                  ],
                  Text(
                    'Tu antena WisBlock no tiene chip GPS propio. Al fijar la ubicación, las coordenadas del teléfono se graban en la memoria Flash de la antena para que las siga transmitiendo de forma autónoma al desconectarte.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (isBleConnected && !provider.isSavingFixedPosition)
                              ? () async {
                                  HapticFeedback.lightImpact();
                                  final ok = await provider.saveCurrentLocationToRadioFlash();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? '✅ Ubicación grabada en memoria Flash del WisBlock.'
                                            : '❌ Error al grabar ubicación en la antena.'),
                                        backgroundColor: ok ? AppTheme.obsidian : AppTheme.redAlert,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: provider.isSavingFixedPosition
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.push_pin_rounded, size: 18),
                          label: Text(
                            provider.isSavingFixedPosition ? 'Grabando en Flash...' : 'Fijar Ubicación en Antena',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (provider.lastFixedPositionSavedAt != null && isBleConnected) ...[
                        const Gap(8),
                        IconButton(
                          tooltip: 'Borrar posición fija guardada',
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final ok = await provider.clearLocationFromRadioFlash();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '🧹 Posición fija eliminada de la memoria Flash.'
                                      : '❌ Error al borrar posición.'),
                                  backgroundColor: AppTheme.obsidian,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.redAlert),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 200.ms).slideY(begin: 0.05, end: 0),

            const Gap(12),

            // 5. Tarjeta de Preferencias y Modo Oscuro
            _buildCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apariencia y Tema',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeSegment(
                          context: context,
                          label: 'Sistema',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: provider.themeMode == ThemeMode.system,
                          onTap: () => provider.setThemeMode(ThemeMode.system),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: _buildThemeSegment(
                          context: context,
                          label: 'Claro',
                          icon: Icons.light_mode_rounded,
                          isSelected: provider.themeMode == ThemeMode.light,
                          onTap: () => provider.setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: _buildThemeSegment(
                          context: context,
                          label: 'Oscuro',
                          icon: Icons.dark_mode_rounded,
                          isSelected: provider.themeMode == ThemeMode.dark,
                          onTap: () => provider.setThemeMode(ThemeMode.dark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 200.ms).slideY(begin: 0.05, end: 0),

            const Gap(16),

            // Botón Desconectar / Conectar Antena BLE
            if (isBleConnected)
              OutlinedButton.icon(
                onPressed: () => _showDisconnectDialog(context),
                icon: const Icon(Icons.bluetooth_disabled_rounded, size: 18, color: AppTheme.redAlert),
                label: const Text(
                  'Desconectar Antena',
                  style: TextStyle(color: AppTheme.redAlert, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppTheme.redAlert.withAlpha(80) : const Color(0xFFFECACA),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => provider.startPairingScan(),
                icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                label: const Text('Vincular / Conectar Antena'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.obsidianCard : AppTheme.obsidian,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const Gap(12),

            // Botón Consola de Logs
            Material(
              color: isDark ? AppTheme.obsidianCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.obsidianBorder : AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.obsidian,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.terminal_rounded,
                          color: isDark ? AppTheme.electricBlue : Colors.white,
                          size: 20,
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consola de Logs en Vivo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Inspeccionar paquetes LoRa, telemetría y BLE',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.textSubtle : AppTheme.textSubtle, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const Gap(12),

            // Botón Guía de Emergencia
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                EmergencyGuideSheet.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redAlert,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 20),
                  Gap(10),
                  Text(
                    'Guía de Emergencia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.obsidianCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.obsidianBorder : AppTheme.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _buildThemeSegment({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.electricBlue.withAlpha(50) : AppTheme.electricBlueLight)
              : (isDark ? AppTheme.obsidianSurface : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.electricBlue
                : (isDark ? AppTheme.obsidianBorder : AppTheme.borderSubtle),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppTheme.electricBlue
                  : (isDark ? AppTheme.textSubtle : AppTheme.textMuted),
            ),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.electricBlue
                    : (isDark ? AppTheme.textSubtle : AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.obsidianSurface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.obsidianBorder : AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isDark ? AppTheme.textSubtle : AppTheme.textMuted),
            const Gap(6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String key,
    String value, {
    bool isLast = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isLast ? 4 : 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                if (trailing != null) ...[
                  const Gap(8),
                  trailing,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final provider = context.read<MeshProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nombre del Nodo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este nombre identificará tus mensajes en la malla LoRa:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
              ),
            ),
            const Gap(14),
            TextField(
              controller: textController,
              autofocus: true,
              maxLength: 30,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textDark,
              ),
              decoration: const InputDecoration(
                hintText: 'Ej. Juan P. - Central',
                counterText: '',
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSubtle : AppTheme.textMuted)),
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
                      content: Text('Nombre de nodo actualizado a "$newName" en radio y malla'),
                      backgroundColor: AppTheme.obsidian,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Desconectar Antena',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textDark,
          ),
        ),
        content: Text(
          '¿Deseas desconectar el enlace Bluetooth con la antena WisBlock RAK4630?\n\nDejarás de recibir telemetría y mensajes de la malla hasta volver a conectarla.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSubtle : AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSubtle : AppTheme.textMuted)),
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
                    backgroundColor: AppTheme.obsidian,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Desconectar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
