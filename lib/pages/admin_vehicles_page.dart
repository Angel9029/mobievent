import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../models/vehicle.dart';

class AdminVehiclesPage extends StatefulWidget {
  const AdminVehiclesPage({super.key});

  @override
  State<AdminVehiclesPage> createState() => _AdminVehiclesPageState();
}

class _AdminVehiclesPageState extends State<AdminVehiclesPage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _driverController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedStatus = 'available';

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _driverController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryService>(context);
    final vehicles = inv.vehicles;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Flota de Vehículos')),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (ctx, i) {
          final v = vehicles[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Column(
              children: [
                ListTile(
                  title: Text(v.plate),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modelo: ${v.model}'),
                      Text('Chofer: ${v.driver}'),
                      Text('Capacidad: ${v.capacity} • Estado: ${v.status}'),
                      Text('Creado: ${v.createdAt.toString().split(' ')[0]}'),
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
                          onPressed: () => _showVehicleModal(context, inv, v),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirm(context, inv, v.id),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleModal(context, inv, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Vehículo'),
      ),
    );
  }

  void _showVehicleModal(BuildContext context, InventoryService inv, Vehicle? vehicle) {
    _plateController.text = vehicle?.plate ?? '';
    _modelController.text = vehicle?.model ?? '';
    _driverController.text = vehicle?.driver ?? '';
    _capacityController.text = vehicle?.capacity.toString() ?? '';
    _selectedStatus = vehicle?.status ?? 'available';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(vehicle != null ? 'Editar Vehículo' : 'Nuevo Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    hintText: 'ABC-1234',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    hintText: 'Ford Transit',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _driverController,
                  decoration: const InputDecoration(
                    labelText: 'Chofer',
                    hintText: 'Juan Pérez',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad (kg)',
                    hintText: '100',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: ['available', 'in_transit', 'maintenance']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? 'available');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (_plateController.text.isEmpty ||
                    _modelController.text.isEmpty ||
                    _driverController.text.isEmpty ||
                    _capacityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                if (vehicle != null) {
                  // Edit existing vehicle
                  await inv.updateVehicle(
                    vehicle.id,
                    _plateController.text,
                    _modelController.text,
                    _driverController.text,
                    int.parse(_capacityController.text),
                    _selectedStatus,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vehículo actualizado')),
                    );
                  }
                } else {
                  // Create new vehicle
                  await inv.createVehicle(
                    _plateController.text,
                    _modelController.text,
                    _driverController.text,
                    int.parse(_capacityController.text),
                    _selectedStatus,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vehículo creado')),
                    );
                  }
                }
              },
              child: Text(vehicle != null ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, InventoryService inv, String vehicleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Vehículo'),
        content: const Text('¿Estás seguro? Se eliminará de la flota.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await inv.deleteVehicle(vehicleId);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehículo eliminado')),
                );
              }
            },
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );
  }
}
