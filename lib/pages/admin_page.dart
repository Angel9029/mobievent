import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/transport_service.dart';
import '../services/inventory_service.dart';
import 'admin_items_page.dart';
import 'admin_reservations_page.dart';


class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transport = Provider.of<TransportService>(context);
    final inv = Provider.of<InventoryService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminItemsPage())), child: const Text('Gestionar items')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminReservationsPage())), child: const Text('Ver reservas')),
            const SizedBox(height: 12),
            const Text('Tarifas de transporte', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Precio por km: \$${transport.perKm.toStringAsFixed(2)}'),
            Slider(
              value: transport.perKm,
              min: 0,
              max: 10,
              divisions: 100,
              label: transport.perKm.toStringAsFixed(2),
              onChanged: (v) => transport.setPerKm(v),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Sede base: Lat ${transport.baseLat.toStringAsFixed(4)} Lng ${transport.baseLng.toStringAsFixed(4)}')),
              IconButton(onPressed: () => _editBaseLocation(context, transport), icon: const Icon(Icons.location_on)),
            ]),
            const SizedBox(height: 12),
            const Text('Tarifas por tipo de artículo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...inv.typeRates.keys.map((t) => _rateRow(context, t)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _rateRow(BuildContext context, String type) {
    final inv = Provider.of<InventoryService>(context);
    final rate = inv.typeRates[type] ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(type)),
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Expanded(child: Text('\$${rate.toStringAsFixed(2)}')),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRate(context, type, rate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editRate(BuildContext context, String type, double current) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar tarifa'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? current;
              Provider.of<InventoryService>(context, listen: false).setRateForType(type, v);
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editBaseLocation(BuildContext context, TransportService transport) {
    final latCtrl = TextEditingController(text: transport.baseLat.toString());
    final lngCtrl = TextEditingController(text: transport.baseLng.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ubicación base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitud'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitud'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            final lat = double.tryParse(latCtrl.text) ?? transport.baseLat;
            final lng = double.tryParse(lngCtrl.text) ?? transport.baseLng;
            transport.setBaseLocation(lat, lng);
            Navigator.of(ctx).pop();
          }, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
