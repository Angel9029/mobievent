import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/reservation.dart';
import '../services/inventory_service.dart';

class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({super.key});

  @override
  State<ReservationHistoryPage> createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('No autenticado'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reservas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(label: Text('Activas'), value: true),
                ButtonSegment<bool>(label: Text('Pasadas'), value: false),
              ],
              selected: {_showActive},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() => _showActive = newSelection.first);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('userId', isEqualTo: userId)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now();
                final reservations = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      try {
                        return Reservation(
                          id: doc.id,
                          userId: data['userId'] ?? '',
                          itemId: data['itemId'] ?? '',
                          qty: (data['qty'] ?? 1) as int,
                          start: (data['start'] as Timestamp).toDate(),
                          end: (data['end'] as Timestamp).toDate(),
                          status: data['status'] ?? 'active',
                          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
                          daysCount: (data['days'] as num?)?.toInt(),
                          pricePerDay: (data['pricePerDay'] as num?)?.toDouble(),
                          totalPrice: (data['totalPrice'] as num?)?.toDouble(),
                          distanceKm: (data['distanceKm'] as num?)?.toDouble(),
                          pickup: data['pickup'] as bool?,
                        );
                      } catch (_) {
                        return null;
                      }
                    })
                    .whereType<Reservation>()
                    .toList();
                // sort client-side by start descending
                reservations.sort((a, b) => b.start.compareTo(a.start));
                final filtered = reservations.where((r) {
                  final isActive = r.end.isAfter(now);
                  return _showActive ? isActive : !isActive;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(_showActive
                        ? 'No hay reservas activas'
                        : 'No hay reservas pasadas'),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final res = filtered[index];
                    final isActive = res.end.isAfter(now);
                    final item = Provider.of<InventoryService>(context, listen: false).findById(res.itemId);
                    final title = item != null ? item.name : res.itemId;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(
                          '${res.start.toString().split(' ')[0]} - ${res.end.toString().split(' ')[0]}\n'
                          'Cantidad: ${res.qty} | Estado: ${res.status}'
                          '${res.daysCount != null ? ' | Días: ${res.daysCount}' : ''}'
                          '${res.totalPrice != null ? ' | Total: \$${res.totalPrice!.toStringAsFixed(2)}' : ''}',
                        ),
                        trailing: isActive
                            ? ElevatedButton(
                                onPressed: () => _cancelReservation(context, res.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Cancelar'),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _cancelReservation(BuildContext context, String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Use InventoryService to update status so local cache stays in sync
              final inv = Provider.of<InventoryService>(context, listen: false);
                  inv.updateReservationStatus(reservationId, 'cancelled');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }
}
