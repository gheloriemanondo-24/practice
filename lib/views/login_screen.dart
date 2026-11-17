import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../validators.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthViewModel auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.student;
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Stands in for the call to the server.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final error = widget.auth.logIn(
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    // On success the app switches to the home screen by itself,
    // so there is nothing more to do here.
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpScreen(auth: widget.auth, initialRole: _role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const TopBar(),
            const SizedBox(height: 28),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Welcome back.\n'),
                  TextSpan(
                    text: 'Log in to order.',
                    style: TextStyle(color: AppColors.tomato),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 28),
            const SectionLabel('I am a'),
            const SizedBox(height: 8),
            RoleSelector(
              selected: _role,
              enabled: !_busy,
              onChanged: (role) => setState(() {
                _role = role;
                _error = null;
              }),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            BigButton(
              label: _busy ? 'LOGGING IN' : 'LOG IN',
              busy: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New here?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: _busy ? null : _openSignUp,
                  child: const Text(
                    'Create an account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
