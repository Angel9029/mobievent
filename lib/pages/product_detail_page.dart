import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/item.dart';
import '../services/cart_service.dart';
import '../services/inventory_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Item item;
  const ProductDetailPage({super.key, required this.item});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;
  DateTime? _start;
  DateTime? _end;
  bool _pickup = true;
  final TextEditingController _distanceController = TextEditingController();
  double? _distanceKm;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final base = _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? base.add(const Duration(days: 1)),
      firstDate: base,
      lastDate: base.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    final inv = context.read<InventoryService>();
    final auth = context.read<AuthService>();
    final isAdmin = auth.currentUser?.isAdmin ?? false;
    final item = widget.item;
    final days = (_start != null && _end != null) ? _end!.difference(_start!).inDays + 1 : 0;
    final pricePerDay = item.pricePerDay > 0.0 ? item.pricePerDay : (inv.typeRates[item.type] ?? 0.0);
    final totalPrice = pricePerDay * days * _qty;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.event_seat, size: 80, color: Colors.grey[600])),
            ),
            const SizedBox(height: 16),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Disponible: ${item.total}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Descripción breve del producto', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 24),

            // Quantity selector
            Text('Cantidad', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(onPressed: () => setState(() { if (_qty > 1) _qty--; }), icon: const Icon(Icons.remove_circle_outline)),
                Text('$_qty', style: Theme.of(context).textTheme.titleLarge),
                IconButton(onPressed: () => setState(() { _qty++; }), icon: const Icon(Icons.add_circle_outline)),
                const SizedBox(width: 16),
                Expanded(child: Text('Precio por día: \$${pricePerDay.toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 16),

            // Dates
            Text('Fechas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(onPressed: _pickStart, child: Text(_start == null ? 'Seleccionar inicio' : _start!.toLocal().toString().split(' ')[0])),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: _start == null ? null : _pickEnd, child: Text(_end == null ? 'Seleccionar fin' : _end!.toLocal().toString().split(' ')[0])),
              ),
            ]),
            const SizedBox(height: 16),

            // Pickup / Delivery
            Text('Entrega', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(label: const Text('Recojo en local'), selected: _pickup, onSelected: (v) => setState(() => _pickup = true)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Entrega a domicilio'), selected: !_pickup, onSelected: (v) => setState(() => _pickup = false)),
              ],
            ),
            const SizedBox(height: 16),

            if (!_pickup)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
              ),

            const SizedBox(height: 24),
            Text('Total estimado: \$${totalPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isAdmin
                  ? ElevatedButton(onPressed: null, child: const Text('Admins no pueden reservar'))
                  : ElevatedButton(
                      onPressed: (_start != null && _end != null)
                          ? () {
                              final distance = !_pickup ? _distanceKm ?? double.tryParse(_distanceController.text.replaceAll(',', '.')) : null;
                              cart.add(item, _qty, _start!, _end!, pickup: _pickup, distanceKm: distance);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregado al carrito')));
                            }
                          : null,
                      child: const Text('Agregar al carrito'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
