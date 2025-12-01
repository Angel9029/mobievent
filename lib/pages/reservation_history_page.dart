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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                    final daysUntilEnd = res.end.difference(now).inDays;
                    final canReschedule = isActive && daysUntilEnd >= 7; // Must reschedule at least 7 days before
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '${res.start.toString().split(' ')[0]} - ${res.end.toString().split(' ')[0]}\n'
                              'Cantidad: ${res.qty} | Estado: ${res.status}'
                              '${res.daysCount != null ? ' | Días: ${res.daysCount}' : ''}'
                              '${res.totalPrice != null ? ' | Total: \$${res.totalPrice!.toStringAsFixed(2)}' : ''}'
                              '${isActive ? ' | Faltan: $daysUntilEnd días' : ''}',
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (canReschedule)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showRescheduleModal(context, res, now),
                                        icon: const Icon(Icons.date_range),
                                        label: const Text('Reprogramar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  if (canReschedule)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _cancelReservation(context, res.id),
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancelar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                  if (!canReschedule)
                                    Expanded(
                                      child: Text(
                                        'Reprogramación no disponible\n(menos de 7 días)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
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

  void _showRescheduleModal(BuildContext context, Reservation res, DateTime now) {
    DateTime? selectedDate = res.end.add(const Duration(days: 1)); // Default to +1 day
    final minDate = now.add(const Duration(days: 7)); // Must be at least 7 days from now
    final maxDate = res.end.add(const Duration(days: 30)); // Can extend up to 30 days

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reprogramar Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha actual: ${res.end.toString().split(' ')[0]}'),
              const SizedBox(height: 16),
              Text('Nueva fecha: ${selectedDate?.toString().split(' ')[0] ?? "Seleccionar"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? res.end,
                    firstDate: minDate,
                    lastDate: maxDate,
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: const Text('Seleccionar fecha'),
              ),
              const SizedBox(height: 12),
              Text(
                'Nota: Debe ser al menos 7 días antes de la entrega',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: selectedDate != null
                  ? () async {
                      final inv = Provider.of<InventoryService>(context, listen: false);
                      await inv.rescheduleReservation(res.id, selectedDate!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Entrega reprogramada para ${selectedDate!.toString().split(' ')[0]}'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
