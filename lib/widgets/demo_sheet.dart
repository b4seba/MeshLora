import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../screens/logs_screen.dart';
import '../theme/app_theme.dart';

void showDemoNavigationModal(BuildContext context) {
  HapticFeedback.lightImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer<MeshProvider>(
      builder: (context, provider, _) {
        final isDemo = provider.isDemoMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.obsidianCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppTheme.obsidianBorder : AppTheme.borderSubtle,
              width: 1,
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle superior
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.borderDark : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(14),

                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.electricBlue.withAlpha(isDark ? 50 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: AppTheme.electricBlue,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Control Demo & Vistas',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Presenta la app sin necesidad de conectar una antena',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                    ),
                  ],
                ),
                const Gap(16),

                // Tarjeta de Switch Modo Demo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDemo
                        ? (isDark ? AppTheme.onlineGreen.withAlpha(25) : const Color(0xFFECFDF5))
                        : (isDark ? AppTheme.obsidianElevated : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDemo
                          ? AppTheme.onlineGreen.withAlpha(80)
                          : (isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDemo ? Icons.bolt_rounded : Icons.sensors_off_rounded,
                        color: isDemo ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                        size: 24,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDemo ? 'Modo Demostración Activo' : 'Modo Demostración Inactivo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                              ),
                            ),
                            Text(
                              isDemo
                                  ? 'Nodos tácticos Concepción + WisBlock simulada'
                                  : 'Usa antena física WisBlock por Bluetooth',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDemo,
                        activeThumbColor: AppTheme.onlineGreen,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          if (val) {
                            provider.enableDemoMode();
                          } else {
                            provider.disableDemoMode();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(18),

                // Sección: Saltar a Cualquier Vista
                Text(
                  'PASAR A LAS SIGUIENTES VISTAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                  ),
                ),
                const Gap(8),

                // Cuadrícula de accesos directos
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.home_rounded,
                      label: 'Inicio (Splash)',
                      onTap: () {
                        provider.goToScreen(AppFlowScreen.splash);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.bluetooth_searching_rounded,
                      label: 'Vincular Antena',
                      onTap: () {
                        provider.goToScreen(AppFlowScreen.pairing);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.person_outline_rounded,
                      label: 'Nombre Usuario',
                      onTap: () {
                        provider.goToScreen(AppFlowScreen.nameInput);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat LoRa',
                      badge: 'Tab 1',
                      onTap: () {
                        if (!isDemo && !provider.isPaired) provider.enableDemoMode();
                        provider.goToScreen(AppFlowScreen.mainNav);
                        provider.setTab(0);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.people_outline_rounded,
                      label: 'Nodos (Lista)',
                      badge: 'Tab 2',
                      onTap: () {
                        if (!isDemo && !provider.isPaired) provider.enableDemoMode();
                        provider.goToScreen(AppFlowScreen.mainNav);
                        provider.setTab(1);
                        provider.setMapView(false);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.map_outlined,
                      label: 'Mapa Táctico',
                      badge: 'Tab 2',
                      onTap: () {
                        if (!isDemo && !provider.isPaired) provider.enableDemoMode();
                        provider.goToScreen(AppFlowScreen.mainNav);
                        provider.setTab(1);
                        provider.setMapView(true);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.sensors_rounded,
                      label: 'Estado y Telemetría',
                      badge: 'Tab 3',
                      onTap: () {
                        if (!isDemo && !provider.isPaired) provider.enableDemoMode();
                        provider.goToScreen(AppFlowScreen.mainNav);
                        provider.setTab(2);
                        Navigator.pop(ctx);
                      },
                    ),
                    _buildNavButton(
                      context: context,
                      isDark: isDark,
                      icon: Icons.terminal_rounded,
                      label: 'Logs de Radio',
                      badge: 'Terminal',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LogsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const Gap(18),

                // Sección: Simulación en Vivo
                Text(
                  'DISPARADORES DE DEMOSTRACIÓN EN VIVO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                  ),
                ),
                const Gap(8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (!isDemo) provider.enableDemoMode();
                          provider.simulateIncomingMessage();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📥 Mensaje de prueba simulado en el Chat'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.mark_email_unread_rounded, size: 16),
                        label: const Text('Simular Mensaje', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          if (!isDemo) provider.enableDemoMode();
                          provider.simulateSosAlert();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🚨 Alerta SOS simulada con éxito'),
                              backgroundColor: Color(0xFFDC2626),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.warning_rounded, size: 16, color: Colors.white),
                        label: const Text('Simular SOS', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      provider.enableDemoMode();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Datos de demostración restablecidos'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay_rounded, size: 15),
                    label: const Text('Restablecer todos los datos demo', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildNavButton({
  required BuildContext context,
  required bool isDark,
  required IconData icon,
  required String label,
  String? badge,
  required VoidCallback onTap,
}) {
  return Material(
    color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 40 - 8) / 2 - 1,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.electricBlue),
            const Gap(8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.electricBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class DemoFloatingBadge extends StatelessWidget {
  const DemoFloatingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final isDemo = provider.isDemoMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showDemoNavigationModal(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDemo
                ? (isDark ? const Color(0xFF064E3B).withAlpha(220) : const Color(0xFFD1FAE5))
                : (isDark ? AppTheme.obsidianElevated : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDemo ? AppTheme.onlineGreen : (isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDemo ? AppTheme.onlineGreen : AppTheme.electricBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(6),
              Text(
                isDemo ? 'DEMO ACTIVO · VISTAS' : 'MODO DEMO / VISTAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: isDemo
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textDark),
                ),
              ),
              const Gap(4),
              Icon(
                Icons.unfold_more_rounded,
                size: 13,
                color: isDemo ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
