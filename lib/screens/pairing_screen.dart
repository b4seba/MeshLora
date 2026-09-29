import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_icons.dart';

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
    final provider = context.watch<MeshProvider>();

    if (provider.currentScreen == AppFlowScreen.pairedSuccess) {
      return Scaffold(
        backgroundColor: AppTheme.lime,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 80,
                      color: AppTheme.lime,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    '¡CONECTADO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Radio RAK4630 vinculada a la red LoRa 915 MHz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: AppTheme.navy,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bluetooth_searching_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'VINCULAR MI RADIO',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Paso 1 de 2 · WisBlock RAK4630 LoRa',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isScanning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lime),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => provider.startPairingScan(),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: 'Reescanear radios',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.startPairingScan(),
                color: AppTheme.navy,
                backgroundColor: AppTheme.lime,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Ilustración visual Celular <-> Radio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PhoneVisualWidget(),
                          const SizedBox(width: 14),
                          _buildConnectionSignal(),
                          const SizedBox(width: 14),
                          RadioNodeVisualWidget(isActive: _isConnecting),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tarjeta de Instrucción
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'Enciende tu antena RAK4630. Selecciónala en la lista de abajo para conectarte a la malla LoRa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3748),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sección de Radios Detectadas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RADIOS DETECTADAS (${discovered.length})',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => provider.startPairingScan(),
                            icon: const Icon(Icons.sync_rounded, size: 16, color: AppTheme.orange),
                            label: Text(
                              isScanning ? 'Escaneando...' : 'Reescanear',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (discovered.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEDF2F7)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.bluetooth_searching_rounded, size: 36, color: AppTheme.textMuted),
                              SizedBox(height: 10),
                              Text(
                                'Buscando dispositivos Bluetooth cercanos...\nDesliza hacia abajo para reescanear.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...discovered.map((dev) {
                          final isThisConnecting = _isConnecting && _connectingDeviceId == dev.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: dev.isLikelyRadio ? AppTheme.lime : const Color(0xFFE2E8F0),
                                width: dev.isLikelyRadio ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: dev.isLikelyRadio
                                      ? AppTheme.lime.withAlpha(30)
                                      : const Color(0xFFEDF2F7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  dev.isLikelyRadio ? Icons.sensors_rounded : Icons.bluetooth_rounded,
                                  color: dev.isLikelyRadio ? AppTheme.lime : const Color(0xFF718096),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                dev.name,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              subtitle: Text(
                                '${dev.id} · Señal: ${dev.rssi} dBm',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: _isConnecting ? null : () => _handleConnect(dev),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dev.isLikelyRadio ? AppTheme.lime : AppTheme.navy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isThisConnecting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'CONECTAR',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Botón Principal Inferior
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () {
                          // Conectar a la primera radio detectada o modo automático
                          if (discovered.isNotEmpty) {
                            _handleConnect(discovered.first);
                          } else {
                            _handleConnect();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnecting ? const Color(0xFF94A3B8) : AppTheme.navy,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: _isConnecting ? 0 : 6,
                    shadowColor: AppTheme.navy.withAlpha(100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        _isConnecting
                            ? 'CONECTANDO...'
                            : (discovered.isNotEmpty
                                ? 'CONECTAR A MI RADIO'
                                : 'VINCULAR MI RADIO'),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
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

  Widget _buildConnectionSignal() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final isLit = _isConnecting;
                return Container(
                  width: 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isLit ? AppTheme.lime : const Color(0xFFCBD5E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 26,
              color: _isConnecting ? AppTheme.lime : const Color(0xFFA0AEC0),
            ),
          ],
        );
      },
    );
  }
}
