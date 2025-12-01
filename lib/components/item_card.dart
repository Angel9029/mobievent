import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final bool available;
  final VoidCallback? onReserve;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, required this.available, this.onReserve, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(width: 56, height: 56, color: Colors.grey[200], child: const Icon(Icons.event_seat)),
        title: Text(item.name),
        subtitle: Text('${item.type} • Disponibles: ${item.total}'),
      ),
    );
  }
}
