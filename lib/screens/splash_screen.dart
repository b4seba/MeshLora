import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              // Logo Central Mesh
              const Hero(
                tag: 'mesh_logo_hero',
                child: MeshLogo(
                  width: 160,
                  height: 110,
                  borderRadius: 20,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  showBorder: true,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),

              const Gap(28),

              // Título Principal
              Text(
                'Alerta Mesh',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: isDark ? Colors.white : AppTheme.textDark,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

              const Gap(10),

              Text(
                'Comunicación de Emergencia Descentralizada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withAlpha(220) : AppTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

              const Gap(6),

              Text(
                'Sin internet · Sin antenas celulares · 100% Offline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textMuted,
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 350.ms),

              const Gap(28),

              // Badges Minimalistas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPillTag(isDark: isDark, icon: Icons.sensors_rounded, text: 'LoRa 915 MHz'),
                  const Gap(8),
                  _buildPillTag(isDark: isDark, icon: Icons.location_on_outlined, text: 'Chile'),
                  const Gap(8),
                  _buildPillTag(isDark: isDark, icon: Icons.shield_outlined, text: 'Red Malla'),
                ],
              ).animate().fadeIn(delay: 450.ms, duration: 350.ms),

              const Spacer(),

              // Botón Comenzar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final provider = context.read<MeshProvider>();
                    provider.startPairingScan();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Gap(8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 550.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

              const Gap(16),

              Text(
                'Proyecto Radio-Mesh Maule · v1.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withAlpha(100) : AppTheme.textSubtle,
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTag({required bool isDark, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(16) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(24) : AppTheme.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.onlineGreen),
          const Gap(6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textDark,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

