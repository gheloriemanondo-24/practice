import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../validators.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets.dart';

// Registration screen.
//
// Flow:
//   1. The person picks a role (Student / Teacher / Stall staff).
//   2. They fill in the form. Each field is checked as they leave it
//      (AutovalidateMode.onUserInteraction) and again when they press
//      CREATE ACCOUNT.
//   3. If everything passes we call AuthViewModel.signUp. It can still reject
//      the request (for example, the email is already taken) and we show that
//      message in a banner above the button.
//   4. On success the person is logged in and this screen closes; main.dart
//      switches to the home screen by itself.
//
// All the validation rules live in lib/validators.dart.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.auth,
    this.initialRole = UserRole.student,
  });

  final AuthViewModel auth;

  // Role that is selected when the screen opens.
  final UserRole initialRole;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Lets us call validate() on the whole form at once.
  final _formKey = GlobalKey<FormState>();

  // Keys for single fields, so we can reset or re-check just that field.
  final _idKey = GlobalKey<FormFieldState<String>>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();

  // One controller per text field so we can read what was typed.
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late UserRole _role = widget.initialRole;
  String? _stall; // only used by stall staff
  bool _hidePassword = true; // eye icon toggles this for BOTH password fields
  bool _busy = false; // true while "talking to the server"
  String? _error; // server-side error shown in the banner

  @override
  void dispose() {
    // Always free controllers, otherwise they leak memory.
    _name.dispose();
    _id.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Called when the person taps a different role.
  void _changeRole(UserRole role) {
    if (role == _role) return;
    setState(() {
      _role = role;
      _error = null;
    });
    // Each role has a different ID format, so whatever was typed no longer
    // applies. reset() empties the field AND clears its error message.
    _idKey.currentState?.reset();
  }

  Future<void> _submit() async {
    // Run every validator. If any fails, the errors show under the fields
    // and Flutter moves focus to the first invalid one.
    if (!_formKey.currentState!.validate()) return;

    // Dismiss the keyboard so the banner / next screen is not covered.
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true; // disables the fields and shows the spinner
      _error = null;
    });

    // Stands in for the call to the server.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // The person may have left the screen while we waited.
    if (!mounted) return;

    final error = widget.auth.signUp(
      // Collapse double spaces: "Ana   Cruz" -> "Ana Cruz".
      name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      email: _email.text,
      password: _password.text,
      idNumber: _id.text.trim().toUpperCase(),
      role: _role,
      // Only stall staff belong to a stall.
      stallName: _role == UserRole.stallStaff ? _stall : null,
    );

    if (error != null) {
      // Rejected by the "server" (e.g. duplicate email). Stay on this screen.
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    // The account is created and logged in. The home screen is already
    // waiting underneath, so just close this screen.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // Back arrow. Disabled while the request is running.
            TopBar(onBack: _busy ? null : () => Navigator.of(context).pop()),
            const SizedBox(height: 16),

            // ---- Headline ------------------------------------------------
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Join CampusEats.\n'),
                  TextSpan(
                    text: 'Eat sooner.',
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

            // ---- Step 1: role --------------------------------------------
            const SectionLabel('I am a'),
            const SizedBox(height: 8),
            RoleSelector(
              selected: _role,
              enabled: !_busy,
              onChanged: _changeRole,
            ),
            // Stall staff get a short explanation of what the account is for.
            if (_role == UserRole.stallStaff) ...[
              const SizedBox(height: 12),
              const _InfoNote(
                'Stall staff accounts manage one stall: its menu, '
                'availability, wait time and incoming orders.',
              ),
            ],
            const SizedBox(height: 24),

            // ---- Step 2: the form ----------------------------------------
            Form(
              key: _formKey,
              // Show a field's error after the person has touched it, not
              // before. Stops the whole form from being red on first open.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  // Full name
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(kMaxNameLength),
                    ],
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: validateFullName,
                  ),
                  const SizedBox(height: 14),

                  // ID number. The label, hint and format change with the role.
                  TextFormField(
                    key: _idKey,
                    controller: _id,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    // Only letters, digits and "-" can be typed, and letters
                    // are shown in capitals ("fac-12" -> "FAC-12").
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                      _UpperCaseFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: _role.idLabel,
                      hintText: 'e.g. ${idExample(_role)}',
                    ),
                    validator: (v) => validateIdNumber(v, _role),
                  ),

                  // Stall dropdown: stall staff only.
                  if (_role == UserRole.stallStaff) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _stall,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      decoration: const InputDecoration(
                        labelText: 'Your food stall',
                      ),
                      items: [
                        for (final place in kPlaces)
                          DropdownMenuItem(
                            value: place.name,
                            child: Text(
                              place.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _stall = value),
                      validator: (v) =>
                          v == null ? 'Choose the stall you work at' : null,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    // No spaces in an email, so block them while typing.
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    // Typing a different email clears the old "already
                    // exists" banner.
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    // Rebuild so the strength meter / checklist update live.
                    onChanged: (_) {
                      setState(() {});
                      // If "Confirm password" was already filled in, re-check
                      // it now that the original changed. (Only that field,
                      // so untouched fields do not turn red.)
                      if (_confirm.text.isNotEmpty) {
                        _confirmKey.currentState?.validate();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: _VisibilityToggle(
                        hidden: _hidePassword,
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: validateNewPassword,
                  ),
                  const SizedBox(height: 10),
                  _PasswordHelper(password: _password.text),
                  const SizedBox(height: 14),

                  // Confirm password
                  TextFormField(
                    key: _confirmKey,
                    controller: _confirm,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    // Pressing "done" on the keyboard submits the form.
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (v) => validateConfirmPassword(v, _password.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Step 3: submit ------------------------------------------
            // Error that came back from the "server".
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            BigButton(
              label: _busy ? 'CREATING ACCOUNT' : 'CREATE ACCOUNT',
              busy: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 12),

            // Link back for people who already have an account.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already registered?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Back to login',
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

// ---------------------------------------------------------------------------
// Small pieces used only by this screen
// ---------------------------------------------------------------------------

// Turns everything typed into capital letters (used for ID numbers).
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // copyWith keeps the cursor where it was.
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// The eye icon at the end of a password field.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.hidden, required this.onPressed});

  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: hidden ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}

// A small grey note with an info icon.
class _InfoNote extends StatelessWidget {
  const _InfoNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.muted, height: 1.3),
          ),
        ),
      ],
    );
  }
}

// Strength meter + rule checklist shown under the password field.
// It is a plain widget: give it the current password and it draws the result,
// so the rules stay in validators.dart.
class _PasswordHelper extends StatelessWidget {
  const _PasswordHelper({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meter: three bars, filled up to the current strength level.
        Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= strength ? AppColors.ink : AppColors.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 6),
            ],
            // Fixed width so the bars do not jump when the word changes.
            SizedBox(
              width: 58,
              child: Text(
                passwordStrengthLabel(strength),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Checklist: a tick appears as each rule is met.
        for (final rule in passwordChecklist(password))
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  rule.met
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: rule.met ? AppColors.ink : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: rule.met ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
