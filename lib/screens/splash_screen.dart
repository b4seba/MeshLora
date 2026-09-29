import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              // Logo Central Mesh
              const Hero(
                tag: 'mesh_logo_hero',
                child: MeshLogo(
                  size: 130,
                  nodeColor: AppTheme.lime,
                  accentColor: AppTheme.orange,
                ),
              ),
              const SizedBox(height: 32),

              // Título y Subtítulo
              const Text(
                'Radio-Mesh',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Barra de acento Lima
              Container(
                width: 64,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.lime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Comunicación de\nEmergencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Sin Internet ni Red Celular',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              const SizedBox(height: 28),

              // Tags Maule · Chile
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPillTag('Maule'),
                  const SizedBox(width: 8),
                  _buildPillTag('LoRa 915 MHz'),
                  const SizedBox(width: 8),
                  _buildPillTag('Chile'),
                ],
              ),
              const Spacer(),

              // Botón Comenzar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final provider = context.read<MeshProvider>();
                    provider.startPairingScan();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.orange.withAlpha(140),
                  ),
                  child: const Text(
                    'COMENZAR',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Versión 1.0 · Proyecto Meshemergencia Maule',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(120),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
