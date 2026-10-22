import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_sheet.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentName = context.read<MeshProvider>().userName;
    _nameController = TextEditingController(text: currentName == 'Juan P.' || currentName == 'Usuario LoRa' ? '' : currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit([String? fallback]) {
    final rawName = _nameController.text.trim();
    final name = rawName.isNotEmpty ? rawName : (fallback ?? 'Operador LoRa');
    HapticFeedback.lightImpact();
    final provider = context.read<MeshProvider>();
    provider.saveUserNameAndContinue(name);
  }

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
              // Icono de Usuario
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricBlue.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms),

              const Gap(28),

              Text(
                '¿Cómo te llamas?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: isDark ? Colors.white : AppTheme.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

              const Gap(8),

              Text(
                'Tu nombre identificará tus mensajes en la malla LoRa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withAlpha(180) : AppTheme.textMuted,
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

              const Gap(32),

              // Campo de Entrada
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.obsidianCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  maxLength: 24,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej. Juan P. - Central',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSubtleDark : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark ? AppTheme.obsidianCard : Colors.white,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

              const Gap(12),

              Text(
                'Máximo 24 caracteres. Recomendamos nombre y ubicación corta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                ),
              ),

              const Spacer(),

              // Botón Continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricBlue,
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
                      Text(
                        'Continuar a la Malla',
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
              ).animate().fadeIn(delay: 450.ms, duration: 300.ms),

              const Gap(8),

              // Botones de navegación directa / Omitir
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<MeshProvider>().goToScreen(AppFlowScreen.pairing);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 14),
                      label: const Text('Volver a Vincular', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _submit('Operador LoRa'),
                      icon: const Icon(Icons.skip_next_rounded, size: 16),
                      label: const Text('Omitir y Entrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),

              const Gap(4),

              Center(
                child: TextButton.icon(
                  onPressed: () => showDemoNavigationModal(context),
                  icon: const Icon(Icons.bolt_rounded, size: 15, color: AppTheme.onlineGreen),
                  label: const Text(
                    'Menú Demo & Vistas Directas',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onlineGreen),
                  ),
                ),
              ),

              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }
}

