import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../models/item.dart';

class AdminItemsPage extends StatelessWidget {
  const AdminItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Items')),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: inv.items.length,
            itemBuilder: (ctx, i) {
              final it = inv.items[i];
              return ListTile(
                title: Text(it.name),
                subtitle: Text('Tipo: ${it.type} • Stock: ${it.total}'),
                trailing: PopupMenuButton<String>(onSelected: (v) async {
                  if (v == 'edit') {
                    await _showEdit(context, inv, it);
                  } else if (v == 'delete') {
                    inv.deleteItem(it.id);
                  }
                }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Editar')), const PopupMenuItem(value: 'delete', child: Text('Eliminar'))]),
              );
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(12.0), child: ElevatedButton(onPressed: () => _showAdd(context, inv), child: const Text('Agregar item')))
      ]),
    );
  }

  Future<void> _showAdd(BuildContext ctx, InventoryService inv) async {
    final name = TextEditingController();
    final type = TextEditingController();
    final stock = TextEditingController(text: '1');
    await showDialog(context: ctx, builder: (_) {
      return AlertDialog(
        title: const Text('Nuevo Item'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: type, decoration: const InputDecoration(labelText: 'Tipo')),
          TextField(controller: stock, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            inv.addItem(name.text.trim(), type.text.trim(), int.tryParse(stock.text) ?? 1);
            Navigator.pop(ctx);
          }, child: const Text('Crear'))
        ],
      );
    });
  }

  Future<void> _showEdit(BuildContext ctx, InventoryService inv, Item it) async {
    final name = TextEditingController(text: it.name);
    final type = TextEditingController(text: it.type);
    final stock = TextEditingController(text: it.total.toString());
    await showDialog(context: ctx, builder: (_) {
      return AlertDialog(
        title: const Text('Editar Item'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: type, decoration: const InputDecoration(labelText: 'Tipo')),
          TextField(controller: stock, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            inv.updateItem(it.id, name.text.trim(), type.text.trim(), int.tryParse(stock.text) ?? it.total);
            Navigator.pop(ctx);
          }, child: const Text('Guardar'))
        ],
      );
    });
  }
}
