import 'package:flutter/material.dart';
import 'admin_products_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_vehicles_page.dart';
import 'admin_settings_page.dart';

class AppShellAdmin extends StatefulWidget {
  const AppShellAdmin({super.key});

  @override
  State<AppShellAdmin> createState() => _AppShellAdminState();
}

class _AppShellAdminState extends State<AppShellAdmin> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const AdminProductsPage(),
          AdminDashboardPage(),
          const AdminVehiclesPage(),
          AdminSettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.manage_search), label: 'Gestionar'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Flota'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}
