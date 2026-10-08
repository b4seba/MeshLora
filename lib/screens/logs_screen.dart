import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
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
        return const Color(0xFF10B981);
      case LogType.loraRx:
        return const Color(0xFF34D399);
      case LogType.loraTx:
        return const Color(0xFF60A5FA);
      case LogType.telemetry:
        return const Color(0xFFFBBF24);
      case LogType.node:
        return const Color(0xFF38BDF8);
      case LogType.ble:
        return const Color(0xFFA78BFA);
      case LogType.warning:
        return const Color(0xFFFB923C);
      case LogType.error:
        return const Color(0xFFF87171);
      case LogType.info:
        return const Color(0xFF94A3B8);
    }
  }

  void _copyAllLogs() {
    HapticFeedback.lightImpact();
    final all = _logger.logs
        .map((l) => '${l.timeFormatted} ${l.typeEmoji} ${l.tag}: ${l.message}${l.rawHex != null ? " [HEX: ${l.rawHex}]" : ""}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: all));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copiados al portapapeles'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.obsidian,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1527),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.onlineGreen,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            const Text(
              'Logs de Antena WisBlock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar antena',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando y vaciando buffer de la radio...'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: AppTheme.obsidian,
                ),
              );
              await context.read<MeshProvider>().refreshAllData();
            },
          ),
          IconButton(
            tooltip: _autoScroll ? 'Pausar auto-scroll' : 'Activar auto-scroll',
            icon: Icon(
              _autoScroll ? Icons.arrow_circle_down_rounded : Icons.pause_circle_outline_rounded,
              color: _autoScroll ? AppTheme.onlineGreen : Colors.white54,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
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
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _logger.clear();
              });
            },
          ),
          const Gap(4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFF1E293B)),
        ),
      ),
      body: Column(
        children: [
          // Barra de Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF0D1527),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', null),
                  const Gap(6),
                  _buildFilterChip('📍 GPS', LogType.gps),
                  const Gap(6),
                  _buildFilterChip('📥 LoRa RX', LogType.loraRx),
                  const Gap(6),
                  _buildFilterChip('🚀 LoRa TX', LogType.loraTx),
                  const Gap(6),
                  _buildFilterChip('⚡ Telemetría', LogType.telemetry),
                  const Gap(6),
                  _buildFilterChip('📡 Nodos', LogType.node),
                  const Gap(6),
                  _buildFilterChip('🔵 BLE', LogType.ble),
                  const Gap(6),
                  _buildFilterChip('❌ Errores', LogType.error),
                ],
              ),
            ),
          ),

          // Lista de Logs en tiempo real
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MeshProvider>().refreshAllData(),
              color: AppTheme.electricBlue,
              backgroundColor: const Color(0xFF0D1527),
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
                              Icon(Icons.terminal_rounded, size: 48, color: Colors.white.withAlpha(40)),
                              const Gap(14),
                              Text(
                                'Esperando tráfico de la antena WisBlock...\nDesliza hacia abajo para forzar sincronización.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
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
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
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
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: typeColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.typeEmoji,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                Expanded(
                                  child: Text(
                                    log.tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Text(
                              log.message,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: const Color(0xFFE2E8F0),
                                height: 1.35,
                              ),
                            ),
                            if (log.rawHex != null && log.rawHex!.isNotEmpty) ...[
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(140),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'HEX: ${log.rawHex}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: const Color(0xFF93C5FD),
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
        HapticFeedback.lightImpact();
        setState(() {
          _selectedFilter = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricBlue : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

