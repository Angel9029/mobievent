import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: user == null
          ? const Center(child: Text('No hay usuario logueado'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [CircleAvatar(radius: 32, child: Text(user.fullName.substring(0, 1).toUpperCase())), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(user.email, style: TextStyle(color: Colors.grey[600]))]))]),
                          const SizedBox(height: 16),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: user.isAdmin ? Colors.red[100] : Colors.blue[100], borderRadius: BorderRadius.circular(8)), child: Text(user.isAdmin ? 'Empleado / Admin' : 'Cliente', style: TextStyle(color: user.isAdmin ? Colors.red[700] : Colors.blue[700], fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(onPressed: () { auth.logout(); Navigator.of(context).popUntil((route) => route.isFirst); }, icon: const Icon(Icons.logout), label: const Text('Cerrar sesión'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                ],
              ),
            ),
    );
  }
}
