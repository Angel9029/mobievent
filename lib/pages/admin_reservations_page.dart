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
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text('Item: ${r.itemId} • Qty: ${r.qty}'),
              subtitle: Text('${r.start.toIso8601String().split('T').first} -> ${r.end.toIso8601String().split('T').first} • Usuario: ${r.userId} • Estado: ${r.status}'),
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
