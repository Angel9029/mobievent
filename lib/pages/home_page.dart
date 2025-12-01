import 'package:flutter/material.dart';
import 'inventory_page.dart';
import 'transport_page.dart';
import 'payment_page.dart';
import 'warehouse_page.dart';
import 'admin_page.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'reservations_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 86, 153, 234),
      appBar: AppBar(title: const Text('MobiEvent'), centerTitle: true, actions: [
        IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartPage())), icon: const Icon(Icons.shopping_cart,)),
        if (auth.isLoggedIn) ...[
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReservationsPage())), icon: const Icon(Icons.event_note)),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())), icon: const Icon(Icons.person)),
        ] else ...[
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())), icon: const Icon(Icons.login)),
        ]
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              auth.isLoggedIn ? Text('Hola, ${auth.currentUser!.fullName}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)) : Text('Bienvenido a MobiEvent', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(auth.currentUser?.isAdmin ?? false ? 'Panel de Administración' : 'Plataforma de alquiler de mobiliario', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _menuCard(context, Icons.inventory, 'Inventario', 'Ver y reservar', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventoryPage()))),
                    _menuCard(context, Icons.local_shipping, 'Transporte', 'Cotizar envío', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransportPage()))),
                    _menuCard(context, Icons.payment, 'Pago', 'Señal y contrato', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentPage()))),
                    _menuCard(context, Icons.warehouse, 'Almacén', 'Panel warehouse', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarehousePage()))),
                    if (auth.currentUser?.isAdmin ?? false) _menuCard(context, Icons.admin_panel_settings, 'Administración', 'Config y CRUD', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPage()))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext ctx, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Theme.of(ctx).colorScheme.primary), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]),
        ),
      ),
    );
  }
}
