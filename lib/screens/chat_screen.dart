import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    final provider = context.read<MeshProvider>();
    provider.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _handleQuickSend(String quickText) {
    final provider = context.read<MeshProvider>();
    provider.sendQuickMessage(quickText);
    _scrollToBottom();
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final provider = context.watch<MeshProvider>();
        final isConnected = provider.deviceStatus.isBleConnected;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tirador superior (Drag Handle)
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Título del Sheet
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'OPCIONES DE MENSAJERÍA',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.navy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected ? AppTheme.lime.withAlpha(30) : const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isConnected ? AppTheme.lime : const Color(0xFFA0AEC0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? 'ANTENA CONECTADA' : 'DESCONECTADA',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isConnected ? const Color(0xFF276749) : const Color(0xFFA0AEC0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Cambiar Nombre del Nodo
                  _buildOptionTile(
                    icon: Icons.badge_rounded,
                    iconBg: AppTheme.navy.withAlpha(20),
                    iconColor: AppTheme.navy,
                    title: 'Cambiar Nombre del Nodo',
                    subtitle: 'Actualmente: "${provider.userName}"',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog(context);
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Consola de Logs
                  _buildOptionTile(
                    icon: Icons.terminal_rounded,
                    iconBg: const Color(0xFF00E676).withAlpha(25),
                    iconColor: const Color(0xFF00C853),
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
                  const SizedBox(height: 10),

                  // 3. Limpiar historial
                  _buildOptionTile(
                    icon: Icons.delete_sweep_rounded,
                    iconBg: const Color(0xFFEDF2F7),
                    iconColor: const Color(0xFF718096),
                    title: 'Limpiar Historial de Chat',
                    subtitle: 'Elimina los mensajes guardados localmente',
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.clearChatHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial de chat local borrado.'),
                          backgroundColor: AppTheme.navy,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 4. Desconectar / Conectar Antena
                  if (isConnected)
                    _buildOptionTile(
                      icon: Icons.bluetooth_disabled_rounded,
                      iconBg: AppTheme.redAlert.withAlpha(25),
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
                      icon: Icons.bluetooth_searching_rounded,
                      iconBg: AppTheme.lime.withAlpha(35),
                      iconColor: AppTheme.lime,
                      title: 'Vincular / Conectar Antena',
                      subtitle: 'Buscar y enlazar con WisBlock RAK4630',
                      titleColor: const Color(0xFF276749),
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
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDF2F7)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: titleColor ?? AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFA0AEC0)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final provider = context.read<MeshProvider>();
    final textController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.navy.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_rounded, color: AppTheme.navy, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nombre del Nodo',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Este nombre identificará tus mensajes en la malla LoRa:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              maxLength: 30,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Ej. Juan P. - Central',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.navy, width: 2),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                provider.updateUserName(newName);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.redAlert.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth_disabled_rounded, color: AppTheme.redAlert, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Desconectar Antena',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas desconectar el enlace Bluetooth con la antena WisBlock RAK4630?\n\nDejarás de recibir telemetría y mensajes en vivo hasta volver a conectarla.',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
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
                    backgroundColor: AppTheme.navy,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('DESCONECTAR', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final messages = provider.messages;
    final activeNeighborsCount = provider.neighbors.where((n) => n.isActive).length;
    final isConnected = provider.deviceStatus.isBleConnected;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          color: AppTheme.navy,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const MeshLogo(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Radio-Mesh',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected ? AppTheme.lime : const Color(0xFFA0AEC0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected
                                  ? 'RED ACTIVA · $activeNeighborsCount nodos en malla'
                                  : 'RADIO DESCONECTADA',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isConnected ? AppTheme.lime : const Color(0xFFA0AEC0),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recargar / Sincronizar Malla',
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sincronizando con la radio LoRa...'),
                          duration: Duration(milliseconds: 900),
                          backgroundColor: AppTheme.navy,
                        ),
                      );
                      await provider.refreshAllData();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Consola de Logs',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LogsScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.terminal_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showChatOptions(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stream de Mensajes con Pull-To-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refreshAllData(),
              color: AppTheme.navy,
              backgroundColor: AppTheme.lime,
              child: Container(
                color: const Color(0xFFF5F7FA),
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
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: Color(0xFFA0AEC0),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Canal LoRa Vacío',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Aún no hay mensajes transmitidos en la malla. Desliza hacia abajo para refrescar o escribe un mensaje.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _buildMessageItem(msg);
                        },
                      ),
              ),
            ),
          ),

          // Barra de Acciones Rápidas y Campo de Entrada
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEDF2F7), width: 1.5),
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
                    const SizedBox(height: 10),

                    // Input de Texto y Botón Enviar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLength: 200,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje para la malla...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFA0AEC0),
                                  fontWeight: FontWeight.w500,
                                ),
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.orange, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: AppTheme.orange,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 4,
                            shadowColor: AppTheme.orange.withAlpha(120),
                            child: InkWell(
                              onTap: _handleSend,
                              borderRadius: BorderRadius.circular(16),
                              child: const SizedBox(
                                width: 54,
                                height: 50,
                                child: Center(
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 24,
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

  Widget _buildMessageItem(ChatMessage msg) {
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
                color: AppTheme.navy,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${msg.formattedTime} · Emitido por LoRa',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
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
          // Avatar Circular con Iniciales
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: msg.avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                msg.initials,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Burbuja de Mensaje Recibido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    msg.name,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: msg.avatarColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: msg.isUrgent ? AppTheme.redAlert : const Color(0xFFE2E8F0),
                      width: msg.isUrgent ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.isUrgent) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.redAlert,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'URGENTE / SOS',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.redAlert,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        msg.text,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${msg.formattedTime}${msg.rssiDbm != null ? ' · RSSI ${msg.rssiDbm} dBm' : ''}${msg.snr != null ? ' · SNR ${msg.snr!.toStringAsFixed(1)} dB' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
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
