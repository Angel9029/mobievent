import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../services/payment_service.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    final pay = Provider.of<PaymentService>(context, listen: false);
    final all = inv.reservations;
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas (Admin)')),
      body: ListView.builder(
        itemCount: all.length,
        itemBuilder: (ctx, i) {
          final r = all[i];
          // Resolve item name from inventory cache
          final item = inv.findById(r.itemId);
          final itemName = item?.name ?? r.itemId;
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text('$itemName • Cantidad: ${r.qty}'),
              subtitle: Text('${r.start.toIso8601String().split('T').first} → ${r.end.toIso8601String().split('T').first} • Precio total: \$${(r.totalPrice ?? 0).toStringAsFixed(2)} • Estado: ${r.status}'),
              trailing: PopupMenuButton<String>(onSelected: (v) {
                if (v == 'cancel') {
                  inv.cancelReservation(r.id);
                  // simulate refund
                  pay.reset();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada y reembolso simulado')));
                } else if (v == 'complete') {
                  inv.updateReservationStatus(r.id, 'completed');
                }
              }, itemBuilder: (_) => [
                const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
                const PopupMenuItem(value: 'complete', child: Text('Marcar completa')),
              ]),
            ),
          );
        },
      ),
    );
  }
}
