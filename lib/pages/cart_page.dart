import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/cart_service.dart';
import '../services/inventory_service.dart';
import '../services/transport_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'reservation_history_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, Map<String, dynamic>> _savedLocations = {};
  String? _selectedLocationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('savedLocations').get();
    final map = <String, Map<String, dynamic>>{};
    for (final d in snap.docs) {
      map[d.id] = d.data();
    }
    if (!mounted) return;
    setState(() => _savedLocations = map);
  }

  Future<void> _saveLocation(String name, double distanceKm) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('savedLocations').add({
      'name': name,
      'distanceKm': distanceKm,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _savedLocations[doc.id] = {'name': name, 'distanceKm': distanceKm};
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final inv = context.read<InventoryService>();
    final transport = context.read<TransportService>();
    final payment = context.read<PaymentService>();
    final auth = context.read<AuthService>();

    double total = 0;
    for (final e in cart.entries) {
      final days = e.days();
      final pricePerDay = e.item.pricePerDay > 0.0 ? e.item.pricePerDay : (inv.typeRates[e.item.type] ?? 0.0);
      double transportCost = 0;
      if (!e.pickup && e.destDistanceKm != null) {
        transportCost = transport.estimateCost(e.destDistanceKm!);
      }
      total += pricePerDay * days * e.qty + transportCost;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: cart.entries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Text('Agrega productos para continuar', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: cart.entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = cart.entries[i];
                        final days = e.days();
                        final ppd = e.item.pricePerDay > 0.0 ? e.item.pricePerDay : (inv.typeRates[e.item.type] ?? 0.0);
                        final price = ppd * days * e.qty;
                        double transportCost = 0;
                        if (!e.pickup && e.destDistanceKm != null) {
                          transportCost = transport.estimateCost(e.destDistanceKm!);
                        }
                        return Card(
                          child: ListTile(
                            title: Text(e.item.name),
                            subtitle: Text('${e.start.toString().split(' ')[0]} → ${e.end.toString().split(' ')[0]} • ${e.qty} uds${e.pickup ? '' : ' • ${e.destDistanceKm?.toStringAsFixed(1) ?? '?'} km'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('\$${(price + transportCost).toStringAsFixed(2)}')]),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => cart.remove(e.id),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Saved locations and checkout section
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_savedLocations.isNotEmpty) ...[
                  const Text('Ubicaciones guardadas', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _savedLocations.entries.map((kv) {
                      final id = kv.key;
                      final data = kv.value;
                      return ChoiceChip(
                        label: Text(data['name'] ?? 'Ubicación'),
                        selected: _selectedLocationId == id,
                        onSelected: (_) => setState(() => _selectedLocationId = id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: cart.entries.isEmpty || auth.currentUser == null || auth.currentUser!.isAdmin
                          ? null
                          : () async {
                              // If user selected a saved location, apply it to delivery entries
                              if (_selectedLocationId != null) {
                                final data = _savedLocations[_selectedLocationId!];
                                final distanceKm = (data?['distanceKm'] as num?)?.toDouble();
                                if (distanceKm != null) {
                                  cart.applySavedLocationToDeliveries(distanceKm: distanceKm);
                                }
                              }

                              final uid = auth.currentUser!.id;
                              if (!context.mounted) return;
                              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                              final results = await cart.checkout(uid, inv, transport, payment);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              final successCount = results.where((r) => r != null).length;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reservas creadas: $successCount/${results.length}')));
                                if (successCount > 0) {
                                  cart.clear();
                                  // After successful checkout navigate to reservation history
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ReservationHistoryPage()));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Confirmar Reserva'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }
}

