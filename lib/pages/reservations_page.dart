import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    final auth = Provider.of<AuthService>(context);
    final pay = Provider.of<PaymentService>(context, listen: false);
    final userId = auth.currentUser?.id;
    final my = userId == null ? [] : inv.reservations.where((r) => r.userId == userId).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: ListView.builder(
        itemCount: my.length,
        itemBuilder: (ctx, i) {
          final r = my[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text('Item: ${r.itemId} • Qty: ${r.qty}'),
              subtitle: Text('${r.start.toIso8601String().split('T').first} -> ${r.end.toIso8601String().split('T').first} • Estado: ${r.status}'),
              trailing: PopupMenuButton<String>(onSelected: (v) {
                if (v == 'cancel') {
                  inv.cancelReservation(r.id);
                  // simulate refund
                  pay.reset();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada y reembolso simulado')));
                }
              }, itemBuilder: (_) => [const PopupMenuItem(value: 'cancel', child: Text('Cancelar'))]),
            ),
          );
        },
      ),
    );
  }
}
