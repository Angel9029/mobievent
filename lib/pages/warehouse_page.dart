import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/inventory_service.dart';

class WarehousePage extends StatelessWidget {
  const WarehousePage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Almacén')),
      body: ListView.builder(
        itemCount: inv.items.length,
        itemBuilder: (ctx, i) {
          final item = inv.items[i];
          final busy = inv.busyDays(item);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('Reservas: ${item.reservations.length} • Días ocupados: ${busy.length}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'block') {
                    // Block today by 1 (admin block)
                    inv.blockDay(item, DateTime.now(), 1);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item bloqueado para hoy (1)')));
                  } else if (v == 'unblock') {
                    inv.unblockDay(item, DateTime.now(), 1);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item desbloqueado para hoy (1)')));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'block', child: Text('Bloquear 1 (hoy)')),
                  const PopupMenuItem(value: 'unblock', child: Text('Desbloquear 1 (hoy)')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
