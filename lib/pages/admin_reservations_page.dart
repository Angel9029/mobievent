import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../services/payment_service.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
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
          
          // Get assigned vehicle name
          final assignedVehicle = r.assignedVehicleId != null 
            ? inv.findVehicleById(r.assignedVehicleId!)
            : null;
          final vehicleDisplay = assignedVehicle != null
            ? '${assignedVehicle.plate} (${assignedVehicle.model})'
            : 'Sin vehículo asignado';
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Column(
              children: [
                ListTile(
                  title: Text('$itemName • Cantidad: ${r.qty}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.start.toIso8601String().split('T').first} → ${r.end.toIso8601String().split('T').first} • Precio total: \$${(r.totalPrice ?? 0).toStringAsFixed(2)} • Estado: ${r.status}'),
                      const SizedBox(height: 4),
                      Text('Vehículo: $vehicleDisplay', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVehicleAssignmentModal(context, inv, r.id),
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Asignar Vehículo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            inv.cancelReservation(r.id);
                            pay.reset();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada y reembolso simulado')));
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            inv.updateReservationStatus(r.id, 'completed');
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Completar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
      ),
    );
  }

  void _showVehicleAssignmentModal(BuildContext context, InventoryService inv, String reservationId) {
    final availableVehicles = inv.vehicles.where((v) => v.status == 'available').toList();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona un vehículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: availableVehicles.length,
                itemBuilder: (_, i) {
                  final v = availableVehicles[i];
                  return ListTile(
                    title: Text(v.plate),
                    subtitle: Text('${v.model} • Capacidad: ${v.capacity} • Chofer: ${v.driver}'),
                    onTap: () async {
                      await inv.assignVehicleToReservation(reservationId, v.id);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Vehículo ${v.plate} asignado'))
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
