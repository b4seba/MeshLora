import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/mesh_provider.dart';
import '../theme/theme.dart';
import '../widgets/demo_sheet.dart';
import '../widgets/mesh_logo.dart';
import '../widgets/quick_message_bar.dart';
import 'logs_screen.dart';

/// ============================================================================
/// PANTALLA PRINCIPAL DE MENSAJES & EMERGENCIAS: 'ALERTA MESH'
/// ============================================================================
/// Cumple estrictamente con:
/// 1. Paleta Corporativa:
///    - #1F74BF: Azul Primario (Acciones primarias, botones principales)
///    - #183B59: Azul Oscuro (Títulos y alto contraste en claro; Fondo en oscuro)
///    - #3D9DD9: Azul Medio (Acentos luminosos y badges interactivos)
///    - #48B0D9: Celeste (Acentos luminosos complementarios y telemetría)
///    - #F2F2F2: Gris Claro (Fondo Scaffold en modo claro; Textos en oscuro)
/// 2. Header / Cabecera Limpia con logo apaisado centralizado y márgenes de 16-24px.
/// 3. Área táctil mínima de 48x48dp en todos los botones (Crítico para emergencias).
/// 4. Bordes redondeados consistentes (14px a 16px) y sombras sutiles.
/// ============================================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  int _unreadNewCount = 0;
  int _previousMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isScrolledUp = _scrollController.offset > 120;
    if (isScrolledUp != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isScrolledUp;
        if (!isScrolledUp) {
          _unreadNewCount = 0;
        }
      });
    } else if (!isScrolledUp && _unreadNewCount > 0) {
      setState(() {
        _unreadNewCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
      if (mounted) {
        setState(() {
          _showScrollToBottom = false;
          _unreadNewCount = 0;
        });
      }
    });
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    final provider = context.read<MeshProvider>();
    provider.sendMessage(text);
    _textController.clear();
    _scrollToBottom(animate: true);
  }

  void _handleQuickSend(String quickText) {
    HapticFeedback.lightImpact();
    final provider = context.read<MeshProvider>();
    provider.sendQuickMessage(quickText);
    _scrollToBottom(animate: true);
  }

  void _showChatOptions(BuildContext context) {
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final provider = context.watch<MeshProvider>();
        final isConnected = provider.deviceStatus.isBleConnected;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppPalette.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppPalette.darkBorder : AppPalette.lightBorderSubtle,
              width: 1,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Opciones de Malla LoRa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? (isDark ? const Color(0x3310B981) : AppPalette.onlineGreenLight)
                              : (isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFE5EBF0)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isConnected
                                ? AppPalette.onlineGreen.withAlpha(100)
                                : (isDark ? AppPalette.darkBorder : AppPalette.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected ? AppPalette.onlineGreen : AppPalette.lightTextSubtle,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              isConnected ? 'Conectado' : 'Desconectado',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isConnected ? AppPalette.onlineGreen : (isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    iconBg: isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFEAF3FB),
                    iconColor: isDark ? AppPalette.skyBlue : AppPalette.primaryBlue,
                    title: 'Cambiar Nombre del Nodo',
                    subtitle: 'Actualmente: "${provider.userName}"',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog(context);
                    },
                  ),
                  const Gap(10),

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.format_size_rounded,
                    iconBg: const Color(0xFFEAF3FB),
                    iconColor: AppPalette.primaryBlue,
                    title: 'Tamaño de Texto (Accesibilidad)',
                    subtitle: 'Escala actual: ${(provider.textScaleFactor * 100).toInt()}% · Aumentar hasta 200%',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showTextScaleModal(context);
                    },
                  ),
                  const Gap(10),

                  if (isConnected) ...[
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.push_pin_outlined,
                      iconBg: isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFEAF3FB),
                      iconColor: isDark ? AppPalette.mediumBlue : AppPalette.primaryBlue,
                      title: 'Fijar Ubicación en Memoria Flash',
                      subtitle: 'Graba el GPS de tu celular en la antena para funcionar desconectado',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ok = await provider.saveCurrentLocationToRadioFlash();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '✅ Ubicación fijada en memoria Flash del WisBlock.'
                                  : '❌ Error al fijar ubicación en la antena.'),
                              backgroundColor: ok ? AppPalette.darkNavy : AppPalette.emergencyRed,
                            ),
                          );
                        }
                      },
                    ),
                    const Gap(10),
                  ],

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.bolt_rounded,
                    iconBg: isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFEAF3FB),
                    iconColor: isDark ? AppPalette.skyBlue : AppPalette.primaryBlue,
                    title: 'Modo Demo & Navegación',
                    subtitle: 'Navegar sin antena física o simular alertas LoRa',
                    onTap: () {
                      Navigator.pop(ctx);
                      showDemoNavigationModal(context);
                    },
                  ),
                  const Gap(10),

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.terminal_rounded,
                    iconBg: isDark ? const Color(0x3310B981) : AppPalette.onlineGreenLight,
                    iconColor: AppPalette.onlineGreen,
                    title: 'Consola de Logs en Vivo',
                    subtitle: 'Inspecciona paquetes crudos HEX y telemetría BLE',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LogsScreen()),
                      );
                    },
                  ),
                  const Gap(10),

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.delete_outline_rounded,
                    iconBg: isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFF0F4F8),
                    iconColor: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
                    title: 'Limpiar Historial Local',
                    subtitle: 'Elimina los mensajes guardados en este dispositivo',
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.clearChatHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial de chat local borrado.'),
                          backgroundColor: AppPalette.darkNavy,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Gap(10),

                  if (isConnected)
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.bluetooth_disabled_rounded,
                      iconBg: isDark ? const Color(0x33E53935) : AppPalette.emergencyRedLight,
                      iconColor: isDark ? const Color(0xFFFF8A80) : AppPalette.emergencyRed,
                      title: 'Desconectar Antena WisBlock',
                      subtitle: 'Corta el enlace Bluetooth con la radio LoRa',
                      titleColor: isDark ? const Color(0xFFFF8A80) : AppPalette.emergencyRed,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDisconnectDialog(context);
                      },
                    )
                  else
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.bluetooth_searching_rounded,
                      iconBg: isDark ? const Color(0x3310B981) : AppPalette.onlineGreenLight,
                      iconColor: AppPalette.onlineGreen,
                      title: 'Vincular / Conectar Antena',
                      subtitle: 'Buscar y enlazar con WisBlock RAK4630',
                      titleColor: AppPalette.onlineGreen,
                      onTap: () {
                        Navigator.pop(ctx);
                        provider.startPairingScan();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
        child: Container(
          constraints: const BoxConstraints(minHeight: AlertaMeshTheme.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppPalette.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
            border: Border.all(
              color: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
              width: 1,
            ),
            boxShadow: isDark ? null : [
              const BoxShadow(
                color: Color(0x06183B59),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? (isDark ? AppPalette.lightGray : AppPalette.darkNavy),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppPalette.darkTextSubtle : AppPalette.lightTextSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón de acción con área táctil mínima de 48x48dp garantizada
  Widget _buildHeaderAction({
    required bool isDark,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
          child: Container(
            width: AlertaMeshTheme.minTouchTarget,
            height: AlertaMeshTheme.minTouchTarget,
            decoration: BoxDecoration(
              color: isDark ? AppPalette.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
              border: Border.all(
                color: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x24000000) : const Color(0x0A183B59),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final isDark = context.isDarkMode;
    final provider = context.read<MeshProvider>();
    final textController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppPalette.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusLarge)),
        title: Text(
          'Nombre del Nodo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este identificador se transmitirá a todos los nodos de la malla LoRa:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
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
                color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
              ),
              decoration: const InputDecoration(
                hintText: 'Ej. Juan P. - Central',
                counterText: '',
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(AlertaMeshTheme.minTouchTarget, AlertaMeshTheme.minTouchTarget),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
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
                      backgroundColor: AppPalette.darkNavy,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, AlertaMeshTheme.minTouchTarget),
              backgroundColor: isDark ? AppPalette.mediumBlue : AppPalette.primaryBlue,
              foregroundColor: isDark ? AppPalette.darkNavy : Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppPalette.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusLarge)),
        title: Text(
          'Desconectar Antena',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
          ),
        ),
        content: Text(
          '¿Deseas desconectar el enlace Bluetooth con la antena WisBlock RAK4630?\n\nDejarás de recibir telemetría y mensajes en vivo hasta volver a conectarla.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(AlertaMeshTheme.minTouchTarget, AlertaMeshTheme.minTouchTarget),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
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
                    backgroundColor: AppPalette.darkNavy,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(90, AlertaMeshTheme.minTouchTarget),
              backgroundColor: AppPalette.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final provider = context.watch<MeshProvider>();
    final messages = provider.messages;
    final activeNeighborsCount = provider.neighbors.where((n) => n.isActive).length;
    final isConnected = provider.deviceStatus.isBleConnected;

    // Detectar si han entrado nuevos mensajes mientras el usuario navega el historial
    if (messages.length > _previousMessagesCount) {
      final diff = messages.length - _previousMessagesCount;
      if (_showScrollToBottom) {
        _unreadNewCount += diff;
      }
      _previousMessagesCount = messages.length;
    } else if (messages.length < _previousMessagesCount) {
      _previousMessagesCount = messages.length;
      _unreadNewCount = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Fondo gris claro #F2F2F2 obligatorio en crisis
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ================================================================
            // HEADER / CABECERA LIMPIA (MÁRGENES 20px, LOGO APAISADO CENTRALIZADO)
            // ================================================================
            _buildCleanHeader(
              context: context,
              isDark: false, // Forzado modo claro
              isConnected: isConnected,
              activeNeighborsCount: activeNeighborsCount,
              provider: provider,
            ),

            // ================================================================
            // STREAM DE MENSAJES (PULL-TO-REFRESH, REVERSE LISTVIEW)
            // ================================================================
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => provider.refreshAllData(),
                    color: isDark ? AppPalette.skyBlue : AppPalette.primaryBlue,
                    backgroundColor: isDark ? AppPalette.darkSurface : Colors.white,
                    child: messages.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppPalette.darkSurface : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
                                            width: 1.2,
                                          ),
                                          boxShadow: isDark
                                              ? null
                                              : [
                                                  const BoxShadow(
                                                    color: Color(0x0C183B59),
                                                    blurRadius: 16,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.radar_rounded,
                                            size: 34,
                                            color: isDark ? AppPalette.skyBlue : AppPalette.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      const Gap(18),
                                      Text(
                                        'Canal Malla LoRa Listo',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppPalette.lightGray : AppPalette.darkNavy,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const Gap(8),
                                      Text(
                                        'No hay transmisiones registradas aún.\nDesliza hacia abajo para sincronizar o emite un mensaje rápido.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollController,
                            reverse: true, // Anclado al último mensaje en la parte inferior
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[messages.length - 1 - index];
                              return _buildMessageItem(msg, isDark);
                            },
                          ),
                  ),

                  // Botón flotante para descender al mensaje más reciente
                  if (_showScrollToBottom)
                    Positioned(
                      right: 20,
                      bottom: 14,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _scrollToBottom(animate: true);
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: AlertaMeshTheme.minTouchTarget),
                          padding: _unreadNewCount > 0
                              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                              : const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppPalette.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? const Color(0x40000000) : const Color(0x1F183B59),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: isDark ? AppPalette.skyBlue : AppPalette.primaryBlue,
                              ),
                              if (_unreadNewCount > 0) ...[
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppPalette.mediumBlue : AppPalette.primaryBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_unreadNewCount nuevo${_unreadNewCount > 1 ? "s" : ""}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ================================================================
            // BARRA DE ACCIONES RÁPIDAS Y ENTRADA DE MENSAJES (48dp Touch Target)
            // ================================================================
            _buildInputArea(isDark: isDark),
          ],
        ),
      ),
    );
  }

  /// ==========================================================================
  /// CABECERA LIMPIA CON ESPACIO CENTRALIZADO PARA EL LOGO APAISADO
  /// Márgenes laterales de 16px a 24px (20px seleccionado)
  /// ==========================================================================
  Widget _buildCleanHeader({
    required BuildContext context,
    required bool isDark,
    required bool isConnected,
    required int activeNeighborsCount,
    required MeshProvider provider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppPalette.darkNavy : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppPalette.darkBorderSubtle : AppPalette.lightBorderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x14000000) : const Color(0x08183B59),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Acción Izquierda: Sincronización Rápida Malla
          _buildHeaderAction(
            isDark: isDark,
            tooltip: 'Sincronizar Malla LoRa',
            icon: Icons.sync_rounded,
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando estado de la red LoRa...'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: AppPalette.darkNavy,
                ),
              );
              await context.read<MeshProvider>().refreshAllData();
            },
          ),

          // Espacio Centralizado para el Logo Apaisado y Badge de Telemetría
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Apaisado Centralizado
                  const MeshLogo(
                    height: 32,
                    fit: BoxFit.contain,
                    borderRadius: 6,
                  ),
                  const Gap(4),

                  // Badge de Estado LoRa / WisBlock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? (isDark ? const Color(0x2810B981) : AppPalette.onlineGreenLight)
                          : (isDark ? AppPalette.darkSurfaceElevated : const Color(0xFFE9EEF2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConnected
                            ? AppPalette.onlineGreen.withAlpha(90)
                            : (isDark ? AppPalette.darkBorder : AppPalette.lightBorderSubtle),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isConnected ? AppPalette.onlineGreen : AppPalette.lightTextSubtle,
                            shape: BoxShape.circle,
                            boxShadow: isConnected
                                ? [
                                    BoxShadow(
                                      color: AppPalette.onlineGreen.withAlpha(120),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          isConnected
                              ? 'MALLA ACTIVA · $activeNeighborsCount NODOS'
                              : 'RADIO DESCONECTADA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isConnected
                                ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                : (isDark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control visual discreto y accesible de tamaño de texto (A- y A+)
          _buildTextScaleHeaderPill(provider),
          const Gap(8),

          // Acciones Derechas: Menú de Opciones
          _buildHeaderAction(
            isDark: isDark,
            tooltip: 'Opciones de Red',
            icon: Icons.more_horiz_rounded,
            onTap: () => _showChatOptions(context),
          ),
        ],
      ),
    );
  }

  /// Botón discreto y accesible para ajustar escala de texto desde la cabecera
  Widget _buildTextScaleHeaderPill(MeshProvider provider) {
    return Tooltip(
      message: 'Tamaño de texto: ${(provider.textScaleFactor * 100).toInt()}%',
      child: Container(
        height: AlertaMeshTheme.minTouchTarget,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
          border: Border.all(
            color: const Color(0x1F183B59),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A183B59),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.decreaseTextScale();
              },
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AlertaMeshTheme.radiusDefault)),
              child: Container(
                width: 32,
                height: AlertaMeshTheme.minTouchTarget,
                alignment: Alignment.center,
                child: Text(
                  'A-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.darkNavy,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 18, color: const Color(0x1F183B59)),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.increaseTextScale();
              },
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AlertaMeshTheme.radiusDefault)),
              child: Container(
                width: 32,
                height: AlertaMeshTheme.minTouchTarget,
                alignment: Alignment.center,
                child: Text(
                  'A+',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.darkNavy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal interactivo de accesibilidad para ajuste visual del texto
  void _showTextScaleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<MeshProvider>(
          builder: (context, mesh, _) {
            final scale = mesh.textScaleFactor;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppPalette.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accesibilidad y Escala de Texto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.darkNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(scale * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => mesh.decreaseTextScale(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F2),
                            foregroundColor: AppPalette.darkNavy,
                            elevation: 0,
                            minimumSize: const Size(54, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('A-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const Gap(10),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppPalette.primaryBlue,
                              thumbColor: AppPalette.primaryBlue,
                            ),
                            child: Slider(
                              value: scale,
                              min: 0.9,
                              max: 2.0,
                              divisions: 7,
                              label: '${(scale * 100).toInt()}%',
                              onChanged: (val) => mesh.setTextScaleFactor(val),
                            ),
                          ),
                        ),
                        const Gap(10),
                        ElevatedButton(
                          onPressed: () => mesh.increaseTextScale(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F2),
                            foregroundColor: AppPalette.darkNavy,
                            elevation: 0,
                            minimumSize: const Size(54, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('A+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Gap(14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('Normal 100%', 1.0, scale, mesh),
                        _buildPresetChip('Grande 130%', 1.3, scale, mesh),
                        _buildPresetChip('Muy Grande 160%', 1.6, scale, mesh),
                        _buildPresetChip('Emergencia 200%', 2.0, scale, mesh),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(String label, double target, double current, MeshProvider mesh) {
    final isSelected = (current - target).abs() < 0.08;
    return InkWell(
      onTap: () => mesh.setTextScaleFactor(target),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.darkNavy : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppPalette.darkNavy,
          ),
        ),
      ),
    );
  }

  /// ==========================================================================
  /// BARRA INFERIOR DE ACCIONES Y ENTRADA DE TEXTO
  /// Todos los botones cumplen con el área táctil mínima de 48x48dp
  /// ==========================================================================
  Widget _buildInputArea({required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppPalette.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.darkBorderSubtle : AppPalette.lightBorderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x06183B59),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de Mensajes Rápidos (48dp de alto garantizado)
              QuickMessageBar(onQuickMessageTapped: _handleQuickSend),
              const Gap(10),

              // Campo de texto y Botón Enviar (48x48dp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLength: 200,
                        minLines: 1,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.darkNavy,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Transmitir mensaje por LoRa...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppPalette.lightTextSubtle,
                          ),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const Gap(10),

                    // Botón Primario de Envío con área táctil mínima de 48x48dp
                    Material(
                      color: isDark ? AppPalette.mediumBlue : AppPalette.primaryBlue,
                      borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
                      elevation: 0,
                      child: InkWell(
                        onTap: _handleSend,
                        borderRadius: BorderRadius.circular(AlertaMeshTheme.radiusDefault),
                        child: SizedBox(
                          width: AlertaMeshTheme.minTouchTarget,
                          height: AlertaMeshTheme.minTouchTarget,
                          child: Center(
                            child: Icon(
                              Icons.send_rounded,
                              color: isDark ? AppPalette.darkNavy : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ==========================================================================
  /// BURBUJAS DE CHAT (BORDES REDONDEADOS 14-16px, SOMBRAS SUTILES)
  /// ==========================================================================
  Widget _buildMessageItem(ChatMessage msg, bool isDark) {
    if (msg.fromMe) {
      // ======================================================================
      // MENSAJES ENVIADOS (SÓLIDO #1F74BF, CERO BORDES, CERO SOMBRAS, TEXTO BLANCO)
      // ======================================================================
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1F74BF), // Sólido #1F74BF
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
                // Cero bordes y cero sombras
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.36,
                ),
              ),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${msg.formattedTime} · Emitido por LoRa',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ========================================================================
    // MENSAJES RECIBIDOS (AVATAR 40x40 SQUIRCLE #183B59, SIN BORDER.ALL, SOMBRA 0.04)
    // ========================================================================
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (Iniciales): Container cuadrado 40x40, borderRadius: 12, SIEMPRE #183B59, texto blanco puro, SIN bordes
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF183B59), // SIEMPRE #183B59
              borderRadius: BorderRadius.circular(12), // Squircle redondeado 12px
              // Sin ningún tipo de borde
            ),
            child: Center(
              child: Text(
                msg.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white, // Blanco puro
                ),
              ),
            ),
          ),
          const Gap(10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identificador del remitente: tamaño 12px, w600, color #183B59
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    msg.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF183B59), // #183B59
                      letterSpacing: -0.1,
                    ),
                  ),
                ),

                // Burbuja del mensaje (Recibido o Alerta SOS)
                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF), // Fondo blanco puro
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(4),
                    ),
                    // Alerta SOS: borde izquierdo grueso de 6px en #183B59
                    // Mensajes Normales: CERO bordes (sin Border.all)
                    border: msg.isUrgent
                        ? const Border(
                            left: BorderSide(
                              color: Color(0xFF183B59), // Línea gruesa de 6px
                              width: 6,
                            ),
                          )
                        : null,
                    // Sombra extremadamente sutil para despegar del fondo gris
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000), // Opacidad exacta 0.04
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distintivo limpio para alerta SOS (sin fondo rosado interior)
                      if (msg.isUrgent) ...[
                        Text(
                          'PRIORIDAD ALTA / SOS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF183B59),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(4),
                      ],

                      // Contenido textual del mensaje
                      Text(
                        msg.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF183B59),
                          height: 1.36,
                        ),
                      ),
                    ],
                  ),
                ),

                // Metadatos (hora, SNR, RSSI): más pequeños (fontSize: 11) en gris discreto #9E9E9E
                const Gap(4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${msg.formattedTime}${msg.rssiDbm != null ? ' · RSSI ${msg.rssiDbm} dBm' : ''}${msg.snr != null ? ' · SNR ${msg.snr!.toStringAsFixed(1)} dB' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
