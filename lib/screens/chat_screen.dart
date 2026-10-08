import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_logo.dart';
import '../widgets/quick_message_bar.dart';
import 'logs_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final provider = context.watch<MeshProvider>();
        final isConnected = provider.deviceStatus.isBleConnected;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.obsidianCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Opciones de Malla',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? (isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight)
                              : (isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isConnected ? AppTheme.onlineGreen : AppTheme.textSubtle,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              isConnected ? 'Conectado' : 'Desconectado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isConnected ? AppTheme.onlineGreen : AppTheme.textSubtle,
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
                    iconBg: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight,
                    iconColor: AppTheme.electricBlue,
                    title: 'Cambiar Nombre del Nodo',
                    subtitle: 'Actualmente: "${provider.userName}"',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog(context);
                    },
                  ),
                  const Gap(8),

                  if (isConnected) ...[
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.push_pin_rounded,
                      iconBg: isDark ? AppTheme.electricBlue.withAlpha(40) : AppTheme.electricBlueLight,
                      iconColor: AppTheme.electricBlue,
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
                              backgroundColor: ok ? AppTheme.obsidian : AppTheme.redAlert,
                            ),
                          );
                        }
                      },
                    ),
                    const Gap(8),
                  ],

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.terminal_rounded,
                    iconBg: isDark ? AppTheme.onlineGreen.withAlpha(40) : const Color(0xFFECFDF5),
                    iconColor: AppTheme.onlineGreen,
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
                  const Gap(8),

                  _buildOptionTile(
                    isDark: isDark,
                    icon: Icons.delete_outline_rounded,
                    iconBg: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
                    iconColor: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                    title: 'Limpiar Historial Local',
                    subtitle: 'Elimina los mensajes guardados en este dispositivo',
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.clearChatHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial de chat local borrado.'),
                          backgroundColor: AppTheme.obsidian,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Gap(8),

                  if (isConnected)
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.bluetooth_disabled_rounded,
                      iconBg: isDark ? AppTheme.redAlert.withAlpha(40) : AppTheme.redAlertLight,
                      iconColor: AppTheme.redAlert,
                      title: 'Desconectar Antena WisBlock',
                      subtitle: 'Corta el enlace Bluetooth con la radio LoRa',
                      titleColor: AppTheme.redAlert,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDisconnectDialog(context);
                      },
                    )
                  else
                    _buildOptionTile(
                      isDark: isDark,
                      icon: Icons.bluetooth_searching_rounded,
                      iconBg: isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight,
                      iconColor: AppTheme.onlineGreen,
                      title: 'Vincular / Conectar Antena',
                      subtitle: 'Buscar y enlazar con WisBlock RAK4630',
                      titleColor: AppTheme.onlineGreen,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? (isDark ? AppTheme.textPrimaryDark : AppTheme.textDark),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
            ],
          ),
        ),
      ),
    );
  }

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
          onTap: onTap,
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
              icon,
              size: 20,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<MeshProvider>();
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
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
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
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
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
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
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
            child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
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
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
          ),
        ),
        content: Text(
          '¿Deseas desconectar el enlace Bluetooth con la antena WisBlock RAK4630?\n\nDejarás de recibir telemetría y mensajes en vivo hasta volver a conectarla.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    'Chat',
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
                          color: isConnected ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                          shape: BoxShape.circle,
                          boxShadow: isConnected
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
                          isConnected
                              ? 'Red Activa · $activeNeighborsCount en malla'
                              : 'Radio Desconectada',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
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
          _buildHeaderAction(
            isDark: isDark,
            tooltip: 'Sincronizar Malla',
            icon: Icons.refresh_rounded,
            onTap: () async {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando con la radio LoRa...'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: AppTheme.obsidian,
                ),
              );
              await provider.refreshAllData();
            },
          ),
          const Gap(6),
          _buildHeaderAction(
            isDark: isDark,
            tooltip: 'Consola de Logs',
            icon: Icons.terminal_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              );
            },
          ),
          const Gap(6),
          _buildHeaderAction(
            isDark: isDark,
            tooltip: 'Opciones',
            icon: Icons.more_vert_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _showChatOptions(context);
            },
          ),
          const Gap(14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Stream de Mensajes con Pull-To-Refresh y Comportamiento WhatsApp
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => provider.refreshAllData(),
                  color: AppTheme.electricBlue,
                  backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
                  child: messages.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.obsidianCard : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 36,
                                        color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                                      ),
                                    ),
                                    const Gap(16),
                                    Text(
                                      'Canal LoRa Vacío',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                      ),
                                    ),
                                    const Gap(6),
                                    Text(
                                      'Aún no hay mensajes transmitidos en la malla.\nDesliza hacia abajo para refrescar o envía un mensaje rápido.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                        height: 1.4,
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
                          reverse: true, // Estilo WhatsApp: anclado al último mensaje en la parte inferior
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[messages.length - 1 - index];
                            return _buildMessageItem(msg, isDark);
                          },
                        ),
                ),

                // Botón Flotante Estilo WhatsApp de "Bajar al último mensaje" / "Nuevos Mensajes"
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _scrollToBottom(animate: true);
                      },
                      child: Container(
                        padding: _unreadNewCount > 0
                            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                            : const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.obsidianCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 60 : 30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                            ),
                            if (_unreadNewCount > 0) ...[
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.electricBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_unreadNewCount nuevo${_unreadNewCount > 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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

          // Barra de Acciones Rápidas y Campo de Entrada
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.obsidianElevated : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botones de Mensajes Rápidos
                    QuickMessageBar(
                      onQuickMessageTapped: _handleQuickSend,
                    ),
                    const Gap(10),

                    // Input de Texto y Botón Enviar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLength: 200,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje para la malla...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                                ),
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          const Gap(8),
                          Material(
                            color: AppTheme.electricBlue,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: _handleSend,
                              borderRadius: BorderRadius.circular(14),
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isDark) {
    if (msg.fromMe) {
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
              decoration: BoxDecoration(
                color: isDark ? AppTheme.electricBlue : AppTheme.obsidian,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
            const Gap(3),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${msg.formattedTime} · Emitido por LoRa',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: msg.avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                msg.initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    msg.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: msg.avatarColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.obsidianCard : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: msg.isUrgent ? AppTheme.redAlert : (isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                      width: msg.isUrgent ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.isUrgent) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.redAlert,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            const Text(
                              'URGENTE / SOS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.redAlert,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const Gap(6),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${msg.formattedTime}${msg.rssiDbm != null ? ' · RSSI ${msg.rssiDbm} dBm' : ''}${msg.snr != null ? ' · SNR ${msg.snr!.toStringAsFixed(1)} dB' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
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

