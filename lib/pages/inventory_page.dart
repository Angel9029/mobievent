import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import 'item_detail_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Inventario'), centerTitle: true),
      body: inv.items.isEmpty
          ? const Center(
              child: Text('No hay productos disponibles en este momento.', style: TextStyle(fontSize: 18)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: inv.items.length,
              itemBuilder: (ctx, i) {
                final item = inv.items[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailPage(item: item))),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Icon(Icons.event_seat, size: 48)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item.type, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Spacer(),
                          Text('Disponibles: ${item.total}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('\$${item.pricePerDay.toStringAsFixed(2)}/día', style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
