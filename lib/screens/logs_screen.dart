import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../services/radio_logger.dart';
import '../theme/app_theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final RadioLogger _logger = RadioLogger();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  LogType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getColorForType(LogType type) {
    switch (type) {
      case LogType.gps:
        return const Color(0xFF00E676); // Verde brillante / GPS
      case LogType.loraRx:
        return const Color(0xFF69F0AE); // Verde menta
      case LogType.loraTx:
        return const Color(0xFF2979FF); // Azul
      case LogType.telemetry:
        return const Color(0xFFFFD600); // Amarillo
      case LogType.node:
        return const Color(0xFF00E5FF); // Cyan
      case LogType.ble:
        return const Color(0xFFB388FF); // Púrpura
      case LogType.warning:
        return const Color(0xFFFF9100); // Naranja
      case LogType.error:
        return const Color(0xFFFF5252); // Rojo
      case LogType.info:
        return const Color(0xFF9E9E9E); // Gris claro
    }
  }

  void _copyAllLogs() {
    final all = _logger.logs
        .map((l) => '${l.timeFormatted} ${l.typeEmoji} ${l.tag}: ${l.message}${l.rawHex != null ? " [HEX: ${l.rawHex}]" : ""}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: all));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copiados al portapapeles'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10192C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'LOGS DE ANTENA',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar antena / Forzar lectura',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando y vaciando buffer de la radio...'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: AppTheme.navy,
                ),
              );
              await context.read<MeshProvider>().refreshAllData();
            },
          ),
          IconButton(
            tooltip: _autoScroll ? 'Pausar auto-scroll' : 'Activar auto-scroll',
            icon: Icon(
              _autoScroll ? Icons.arrow_downward_rounded : Icons.pause_circle_outline_rounded,
              color: _autoScroll ? const Color(0xFF00E676) : Colors.white54,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
              if (_autoScroll) _scrollToBottom();
            },
          ),
          IconButton(
            tooltip: 'Copiar logs',
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            onPressed: _copyAllLogs,
          ),
          IconButton(
            tooltip: 'Limpiar logs',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white54, size: 22),
            onPressed: () {
              setState(() {
                _logger.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF131D33),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', null),
                  const SizedBox(width: 6),
                  _buildFilterChip('📍 GPS', LogType.gps),
                  const SizedBox(width: 6),
                  _buildFilterChip('📥 LoRa RX', LogType.loraRx),
                  const SizedBox(width: 6),
                  _buildFilterChip('🚀 LoRa TX', LogType.loraTx),
                  const SizedBox(width: 6),
                  _buildFilterChip('⚡ Telemetría', LogType.telemetry),
                  const SizedBox(width: 6),
                  _buildFilterChip('📡 Nodos', LogType.node),
                  const SizedBox(width: 6),
                  _buildFilterChip('🔵 BLE', LogType.ble),
                  const SizedBox(width: 6),
                  _buildFilterChip('❌ Errores', LogType.error),
                ],
              ),
            ),
          ),

          // Lista de Logs en tiempo real
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MeshProvider>().refreshAllData(),
              color: AppTheme.navy,
              backgroundColor: AppTheme.lime,
              child: StreamBuilder<RadioLogEntry>(
                stream: _logger.logStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _scrollToBottom();
                  }

                  final filteredLogs = _selectedFilter == null
                      ? _logger.logs
                      : _logger.logs.where((l) => l.type == _selectedFilter).toList();

                  if (filteredLogs.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.terminal_rounded, size: 56, color: Colors.white.withAlpha(50)),
                              const SizedBox(height: 12),
                              Text(
                                'Esperando tráfico de la antena WisBlock...\nDesliza hacia abajo para forzar sincronización.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(120),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final typeColor = _getColorForType(log.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101726),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: typeColor.withAlpha(40),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  log.timeFormatted,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Color(0xFF7E8B9B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: typeColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.typeEmoji,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    log.tag,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: typeColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              log.message,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Color(0xFFE2E8F0),
                                height: 1.35,
                              ),
                            ),
                            if (log.rawHex != null && log.rawHex!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(120),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HEX: ${log.rawHex}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Color(0xFF90CAF9),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, LogType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lime : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? AppTheme.navy : Colors.white70,
          ),
        ),
      ),
    );
  }
}
