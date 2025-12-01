import 'package:flutter/material.dart';
import 'inventory_page.dart';
import 'reservation_history_page.dart';
import 'cart_page.dart';
import 'account_settings_page.dart';

class AppShellClient extends StatefulWidget {
  const AppShellClient({super.key});

  @override
  State<AppShellClient> createState() => _AppShellClientState();
}

class _AppShellClientState extends State<AppShellClient> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          InventoryPage(),
          ReservationHistoryPage(),
          CartPage(),
          AccountSettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Inventario', backgroundColor: Colors.blue ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
