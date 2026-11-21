import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/order_view_model.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';

void main() => runApp(
  CampusEatsApp(store: OrderViewModel(), auth: AuthViewModel()),
);

class CampusEatsApp extends StatelessWidget {
  const CampusEatsApp({super.key, required this.store, required this.auth});

  final OrderViewModel store;
  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusEats',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Logged out people see the login screen, logged in people see home.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.isLoggedIn) {
            return HomeScreen(store: store, auth: auth);
          }
          return LoginScreen(auth: auth);
        },
      ),
    );
  }
}
