import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'models/models.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/order_view_model.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'views/stall_dashboard_screen.dart';

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
      // Logged out people see the login screen. Stall staff go straight to the
      // dashboard for the stall they registered with; students and teachers
      // see the ordering home.
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final user = auth.currentUser;
          if (user == null) return LoginScreen(auth: auth);
          final stall = user.stallName;
          if (user.role == UserRole.stallStaff && stall != null) {
            return StallDashboardScreen(
              store: store,
              auth: auth,
              stallName: stall,
            );
          }
          return HomeScreen(store: store, auth: auth);
        },
      ),
    );
  }
}
