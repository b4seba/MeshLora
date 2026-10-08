import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_logo.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isConnecting = false;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Iniciar escaneo BLE automáticamente al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeshProvider>().startPairingScan();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect([dynamic deviceOrId]) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isConnecting = true;
      if (deviceOrId is DiscoveredRadioDevice) {
        _connectingDeviceId = deviceOrId.id;
      }
    });

    final provider = context.read<MeshProvider>();
    await provider.connectToRadio(deviceOrId);

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _connectingDeviceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MeshProvider>();

    if (provider.currentScreen == AppFlowScreen.pairedSuccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.onlineGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.onlineGreen.withAlpha(80),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), curve: Curves.easeOutBack)
                      .fadeIn(duration: 300.ms),
                  const Gap(28),
                  Text(
                    '¡Conectado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textDark,
                      letterSpacing: -0.6,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                  const Gap(8),
                  Text(
                    'Radio WisBlock vinculada a la red LoRa 915 MHz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withAlpha(200) : AppTheme.textMuted,
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
                  const Gap(40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.completePairing();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continuar a Alerta Mesh',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final discovered = provider.discoveredDevices;
    final isScanning = provider.bleService.currentState == BleConnectionState.scanning;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vincular Antena'),
            Text(
              'Paso 1 de 2 · WisBlock RAK4630 LoRa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.startPairingScan();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Reescanear radios',
            ),
          const Gap(4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.startPairingScan(),
                color: AppTheme.electricBlue,
                backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      // Ilustración de Vinculación
                      _buildVisualIllustration(isDark),
                      const Gap(16),

                      // Tarjeta de Instrucción
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.obsidianCard : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.electricBlue),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                'Enciende tu antena WisBlock. Selecciónala abajo para enlazar por Bluetooth.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Sección de Radios Detectadas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Radios Detectadas (${discovered.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              provider.startPairingScan();
                            },
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: AppTheme.electricBlue,
                                ),
                                Gap(4),
                                Text(
                                  'Reescanear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.electricBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),

                      if (discovered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.obsidianCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.bluetooth_searching_rounded, size: 36, color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                              const Gap(10),
                              Text(
                                'Buscando dispositivos Bluetooth cercanos...\nDesliza hacia abajo para reescanear.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...discovered.map((dev) {
                          final isThisConnecting = _isConnecting && _connectingDeviceId == dev.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.obsidianCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: dev.isLikelyRadio ? AppTheme.electricBlue : (isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                                width: dev.isLikelyRadio ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: dev.isLikelyRadio
                                        ? (isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight)
                                        : (isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    dev.isLikelyRadio ? Icons.cell_tower_rounded : Icons.bluetooth_rounded,
                                    color: dev.isLikelyRadio ? AppTheme.electricBlue : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                                    size: 20,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dev.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                        ),
                                      ),
                                      const Gap(2),
                                      Text(
                                        '${dev.id} · RSSI: ${dev.rssi} dBm',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(8),
                                ElevatedButton(
                                  onPressed: _isConnecting ? null : () => _handleConnect(dev),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dev.isLikelyRadio ? AppTheme.electricBlue : (isDark ? AppTheme.obsidianElevated : AppTheme.obsidian),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  child: isThisConnecting
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Conectar'),
                                ),
                              ],
                            ),
                          );
                        }),
                      const Gap(16),
                    ],
                  ),
                ),
              ),
            ),

            // Botón Inferior
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () {
                          if (discovered.isNotEmpty) {
                            _handleConnect(discovered.first);
                          } else {
                            _handleConnect();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnecting ? const Color(0xFF94A3B8) : AppTheme.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const Gap(10),
                      ],
                      Text(
                        _isConnecting
                            ? 'Conectando...'
                            : (discovered.isNotEmpty ? 'Conectar a mi Radio' : 'Buscar Radios'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualIllustration(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.obsidianCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Teléfono
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle, width: 1.5),
            ),
            child: const Center(
              child: MeshLogo(size: 28, borderRadius: 6),
            ),
          ),
          const Gap(16),

          // Señal de conexión animada
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final isLit = _isConnecting;
                      return Container(
                        width: 6,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isLit ? AppTheme.electricBlue : (isDark ? AppTheme.borderDark : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _isConnecting ? AppTheme.electricBlue : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                  ),
                ],
              );
            },
          ),
          const Gap(16),

          // Antena WisBlock
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: _isConnecting
                  ? (isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight)
                  : (isDark ? AppTheme.obsidianElevated : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isConnecting ? AppTheme.electricBlue : (isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.cell_tower_rounded,
                size: 28,
                color: _isConnecting ? AppTheme.electricBlue : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

