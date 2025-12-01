import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/inventory_service.dart';
import 'services/transport_service.dart';
import 'services/payment_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'pages/login_page.dart';
import 'pages/app_shell_client.dart';
import 'pages/app_shell_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..checkAuthState()),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => TransportService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        title: 'MobiEvent',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (!authService.isLoggedIn) {
              return const LoginPage();
            }
            return authService.currentUser!.isAdmin
                ? const AppShellAdmin()
                : const AppShellClient();
          },
        ),
      ),
    );
  }
}
