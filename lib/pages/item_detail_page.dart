import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

import '../models/item.dart';
import '../services/inventory_service.dart';
import '../services/cart_service.dart';
import '../components/availability_calendar.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 1));
  int _qty = 1;
  bool _pickup = true;
  final TextEditingController _distanceController = TextEditingController();
  double? _distanceKm;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    final cart = Provider.of<CartService>(context);
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.currentUser?.isAdmin ?? false;
    final available = inv.availableForRange(widget.item, _start, _end);
    final days = _end.difference(_start).inDays + 1;
    final price = inv.priceFor(widget.item, days) * _qty;
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 180, color: Colors.grey[200], child: const Center(child: Icon(Icons.photo, size: 64))),
          const SizedBox(height: 12),
          AvailabilityCalendar(item: widget.item, desiredQty: _qty, daysToShow: 30),
          const SizedBox(height: 12),
          Text(widget.item.type, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(widget.item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Precio por día: \$${(widget.item.pricePerDay > 0 ? widget.item.pricePerDay : (inv.typeRates[widget.item.type] ?? 0.0)).toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('Desde: ${DateFormat('yyyy-MM-dd').format(_start)}')),
            ElevatedButton(onPressed: _pickStart, child: const Text('Fecha inicio')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Hasta: ${DateFormat('yyyy-MM-dd').format(_end)}')),
            ElevatedButton(onPressed: _pickEnd, child: const Text('Fecha fin')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Cantidad:'),
            const SizedBox(width: 8),
            DropdownButton<int>(value: _qty, items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(), onChanged: (v) => setState(() => _qty = v ?? 1)),
            const Spacer(),
            Checkbox(value: _pickup, onChanged: (v) => setState(() => _pickup = v ?? true)),
            const Text('Recoger en local'),
          ]),
          const SizedBox(height: 8),
          if (!_pickup)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Distancia de entrega (km)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _distanceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Kilómetros',
                    hintText: 'Ejemplo: 5.0',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      _distanceKm = parsed;
                    });
                  },
                ),
              ]),
            ),
          const SizedBox(height: 8),
          Text('Días: $days • Precio total estimado: \$${price.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Disponibilidad para rango: $available disponibles'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: isAdmin
                    ? ElevatedButton(onPressed: null, child: const Text('Admins no pueden reservar'))
                    : ElevatedButton(onPressed: available >= _qty ? () => _addToCart(cart) : null, child: const Text('Agregar al carrito'))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => _showQuote(inv, price), child: const Text('Cotizar')),
          ])
        ]),
      ),
    );
  }

  void _addToCart(CartService cart) {
    final distance = !_pickup ? _distanceKm ?? double.tryParse(_distanceController.text.replaceAll(',', '.')) : null;
    cart.add(widget.item, _qty, _start, _end, pickup: _pickup, distanceKm: distance);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregado al carrito')));
  }

  void _showQuote(InventoryService inv, double price) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Cotización'), content: Text('Precio estimado: \$${price.toStringAsFixed(2)}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime.now().subtract(const Duration(days: 0)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(context: context, initialDate: _end, firstDate: _start, lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _end = d);
  }


}
