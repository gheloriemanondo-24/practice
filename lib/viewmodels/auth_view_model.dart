import 'package:flutter/foundation.dart';

import '../models/models.dart';

// Handles sign up, log in and log out.
//
// Accounts live in memory only, so they disappear when the app restarts.
// A real app would send these calls to a server and never keep or compare
// plain text passwords on the device.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({bool withDemoAccounts = true}) {
    if (withDemoAccounts) {
      // so the app can be tried without signing up first
      _users.addAll(const [
        AppUser(
          name: 'Maria Santos',
          email: 'student@campus.edu',
          password: 'student123',
          role: UserRole.student,
          idNumber: '2024-00123',
        ),
        AppUser(
          name: 'Jose Reyes',
          email: 'teacher@campus.edu',
          password: 'teacher123',
          role: UserRole.teacher,
          idNumber: 'FAC-0456',
        ),
        AppUser(
          name: 'Nena Cruz',
          email: 'staff@campus.edu',
          password: 'staff123',
          role: UserRole.stallStaff,
          idNumber: 'STF-0789',
          stallName: "Aling Nena's Karinderya",
        ),
      ]);
    }
  }

  final List<AppUser> _users = [];
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static String _clean(String email) => email.trim().toLowerCase();

  // Creates the account and logs the person in.
  // Returns null on success, or a message to show the person.
  String? signUp({
    required String name,
    required String email,
    required String password,
    required String idNumber,
    required UserRole role,
    String? stallName,
  }) {
    final cleanEmail = _clean(email);
    final taken = _users.any((u) => u.email == cleanEmail);
    if (taken) {
      return 'An account with this email already exists. Try logging in.';
    }

    final user = AppUser(
      name: name.trim(),
      email: cleanEmail,
      password: password,
      role: role,
      idNumber: idNumber.trim(),
      stallName: stallName,
    );
    _users.add(user);
    _currentUser = user;
    notifyListeners();
    return null;
  }

  // Returns null on success, or a message to show the person.
  String? logIn({
    required String email,
    required String password,
    required UserRole role,
  }) {
    final cleanEmail = _clean(email);
    AppUser? match;
    for (final user in _users) {
      if (user.email == cleanEmail && user.password == password) {
        match = user;
        break;
      }
    }
    if (match == null) return 'Wrong email or password.';
    if (match.role != role) {
      return 'This account is registered as a ${match.role.label.toLowerCase()}. '
          'Switch the role above and try again.';
    }

    _currentUser = match;
    notifyListeners();
    return null;
  }

  void logOut() {
    _currentUser = null;
    notifyListeners();
  }
}
