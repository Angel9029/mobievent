import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../models/item.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestionar Productos'),
        centerTitle: true,
      ),
      body: inv.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('No hay productos en el inventario.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Crear datos de ejemplo'),
                    onPressed: () async {
                      await inv.seedDefaultItems();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos de ejemplo creados')));
                    },
                  ),
                ]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: inv.items.length,
              itemBuilder: (ctx, i) {
                final item = inv.items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.type} • ${item.total} disponibles • \$${item.pricePerDay.toStringAsFixed(2)}/día'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditItemDialog(context, inv, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirm(context, inv, item.id, item.name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        onPressed: () => _showAddItemDialog(context, inv),
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context, InventoryService inv) async {
    final nameC = TextEditingController();
    final totalC = TextEditingController();
    String selectedType = inv.typeRates.keys.isNotEmpty ? inv.typeRates.keys.first : 'other';
    final imageC = TextEditingController();
    final priceC = TextEditingController();
    final unitC = TextEditingController();

    final saved = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Producto'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedType,
                items: inv.typeRates.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => selectedType = v ?? selectedType),
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad disponible',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio por día',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageC,
              keyboardType: TextInputType.text,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Imagen (base64 o URL)',
                hintText: 'Opcional - Recomendado: Firebase Storage para producción',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final name = nameC.text.trim();
      final total = int.tryParse(totalC.text) ?? 1;
      final price = double.tryParse(priceC.text.replaceAll(',', '.')) ?? 0.0;
      final unit = double.tryParse(unitC.text.replaceAll(',', '.')) ?? price;
      final imageRaw = imageC.text.trim();
      final imageVal = imageRaw.isEmpty ? null : imageRaw;

      if (name.isNotEmpty) {
        inv.addItem(name, selectedType, total, imageBase64: imageVal, pricePerDay: price, unitPrice: unit);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido')));
      }
    }
  }

  Future<void> _showEditItemDialog(BuildContext context, InventoryService inv, Item item) async {
    final nameC = TextEditingController(text: item.name);
    final totalC = TextEditingController(text: item.total.toString());
    String selectedType = item.type;
    final imageC = TextEditingController(text: item.imageBase64 ?? '');
    final priceC = TextEditingController(text: item.pricePerDay.toString());
    final unitC = TextEditingController(text: item.unitPrice.toString());

    final saved = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedType,
                items: inv.typeRates.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => selectedType = v ?? selectedType),
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: totalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad disponible',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio por día',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageC,
              keyboardType: TextInputType.text,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Imagen (base64 o URL)',
                hintText: 'Opcional',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final name = nameC.text.trim();
      final total = int.tryParse(totalC.text) ?? item.total;
      final price = double.tryParse(priceC.text.replaceAll(',', '.')) ?? item.pricePerDay;
      final unit = double.tryParse(unitC.text.replaceAll(',', '.')) ?? item.unitPrice;
      final imageRaw = imageC.text.trim();
      final imageVal = imageRaw.isEmpty ? null : imageRaw;

      if (name.isNotEmpty) {
        inv.updateItem(item.id, name, selectedType, total, imageBase64: imageVal, pricePerDay: price, unitPrice: unit);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido')));
      }
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, InventoryService inv, String itemId, String itemName) async {
    final confirm = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      inv.deleteItem(itemId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$itemName" eliminado')));
    }
  }
}
