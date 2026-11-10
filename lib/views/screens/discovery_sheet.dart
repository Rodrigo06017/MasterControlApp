import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/xbox_theme.dart';
import '../../viewmodels/controller_viewmodel.dart';

class DiscoverySheet extends StatefulWidget {
  const DiscoverySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DiscoverySheet(),
    );
  }

  @override
  State<DiscoverySheet> createState() => _DiscoverySheetState();
}

class _DiscoverySheetState extends State<DiscoverySheet> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ControllerViewModel>().startScan();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ControllerViewModel>();
    final isScanning = vm.connectionState == ConnectionStateEnum.scanning;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: XboxTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: XboxTheme.xboxGreen, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: XboxTheme.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONECTAR A XBOX',
                style: TextStyle(
                  color: XboxTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: XboxTheme.neonGreen,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: XboxTheme.neonGreen),
                  tooltip: 'Volver a escanear',
                  onPressed: () => vm.startScan(),
                ),
            ],
          ),

          if (vm.statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.statusMessage!,
              style: const TextStyle(
                color: XboxTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Manual IP Connect Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: XboxTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: XboxTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.datetime,
                    style: const TextStyle(color: XboxTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ingresa IP de tu Xbox (ej. 192.168.1.45)',
                      hintStyle: TextStyle(color: XboxTheme.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XboxTheme.xboxGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) {
                      final success = await vm.connectByIp(ip);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Conectar'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Consoles list title
          const Text(
            'CONSOLAS DETECTADAS EN TU RED',
            style: TextStyle(
              color: XboxTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // List of found devices
          Expanded(
            child: vm.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_tethering_error_rounded,
                          size: 48,
                          color: XboxTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No se detectaron consolas automáticamente',
                          style: TextStyle(color: XboxTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Asegúrate de tener activa la opción "Permitir conexiones desde cualquier dispositivo" en tu Xbox o ingresa su IP arriba.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: XboxTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: vm.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = vm.discoveredDevices[index];
                      final isCurrent = vm.activeDevice?.ip == device.ip;

                      return Card(
                        color: isCurrent ? XboxTheme.xboxGreen.withValues(alpha: 0.2) : XboxTheme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isCurrent ? XboxTheme.neonGreen : XboxTheme.divider,
                            width: 1.5,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: XboxTheme.surfaceBright,
                            child: Icon(Icons.videogame_asset_rounded, color: XboxTheme.neonGreen),
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(
                              color: XboxTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${device.ip}:${device.port}',
                            style: const TextStyle(color: XboxTheme.textSecondary, fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent ? Colors.red.shade900 : XboxTheme.xboxGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (isCurrent) {
                                await vm.disconnect();
                              } else {
                                final ok = await vm.connectTo(device);
                                if (ok && context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            child: Text(isCurrent ? 'Desconectar' : 'Conectar'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
