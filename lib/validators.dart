// Form validators for CampusEats.
//
// How to read this file:
//   * A `validateXxx` function plugs straight into a TextFormField's
//     `validator:` argument. It returns an error message to show under the
//     field, or `null` when the value is fine.
//   * Rules live here (not inside the screens) so the login screen, the sign
//     up screen and the unit tests all use exactly the same checks.

import 'models/models.dart';

// ---------------------------------------------------------------------------
// Settings you may want to change in one place
// ---------------------------------------------------------------------------

/// Shortest password we accept when creating an account.
const int kMinPasswordLength = 8;

/// Longest values we accept. Stops absurdly long input.
const int kMaxNameLength = 60;
const int kMaxEmailLength = 254; // the limit from the email standard

// ID formats. These match the demo accounts in AuthViewModel.
// TODO(team): change these patterns if the school uses different ID formats.
final RegExp _studentIdPattern = RegExp(r'^\d{4}-\d{5}$'); // 2024-00123
final RegExp _facultyIdPattern = RegExp(r'^FAC-\d{4}$'); // FAC-0456
final RegExp _staffIdPattern = RegExp(r'^STF-\d{4}$'); // STF-0789

// ---------------------------------------------------------------------------
// Basic fields
// ---------------------------------------------------------------------------

/// Generic "this field must not be empty" check.
/// [what] completes the sentence: "Enter your $what".
String? validateRequired(String? value, String what) {
  if (value == null || value.trim().isEmpty) return 'Enter your $what';
  return null;
}

/// Full name: letters, spaces and the punctuation found in real names
/// (. ' -), at least a first and a last name.
String? validateFullName(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Enter your full name';
  if (text.length > kMaxNameLength) {
    return 'Name is too long (max $kMaxNameLength characters)';
  }
  // The À-ÿ ranges allow accented letters such as the ñ in "Niño".
  final onlyNameCharacters = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ .'\-]*$",
  ).hasMatch(text);
  if (!onlyNameCharacters) {
    return "Use letters only (spaces, . ' and - are fine)";
  }
  // "Maria" alone is not a full name. Split on any run of spaces.
  if (text.split(RegExp(r'\s+')).length < 2) {
    return 'Enter your first and last name';
  }
  return null;
}

/// Email: not empty, one "@", no spaces, a dot in the domain, no "..".
/// This is a sanity check, not proof the mailbox exists.
String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email';
  if (text.length > kMaxEmailLength) return 'That email is too long';
  final looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
  if (!looksValid || text.contains('..')) {
    return 'Enter a valid email address';
  }
  return null;
}

// ---------------------------------------------------------------------------
// ID number (depends on the selected role)
// ---------------------------------------------------------------------------

/// Example shown as hint text under the ID field, e.g. "2024-00123".
String idExample(UserRole role) => switch (role) {
  UserRole.student => '2024-00123',
  UserRole.teacher => 'FAC-0456',
  UserRole.stallStaff => 'STF-0789',
};

/// Student ID / Faculty ID / Staff ID. Each role has its own format.
/// Case does not matter: "fac-0456" is accepted (the screen upper-cases it).
String? validateIdNumber(String? value, UserRole role) {
  final text = (value ?? '').trim().toUpperCase();
  // Same wording as before: "Enter your student id".
  if (text.isEmpty) return 'Enter your ${role.idLabel.toLowerCase()}';

  final pattern = switch (role) {
    UserRole.student => _studentIdPattern,
    UserRole.teacher => _facultyIdPattern,
    UserRole.stallStaff => _staffIdPattern,
  };
  if (!pattern.hasMatch(text)) {
    return 'Use the format ${idExample(role)}';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Passwords
// ---------------------------------------------------------------------------

/// Used by the LOGIN screen: we only need to know something was typed.
/// (Checking strength on login would lock out people with older passwords.)
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Enter your password';
  return null;
}

/// One line of the live checklist under the password field.
typedef PasswordRule = ({String label, bool met});

/// The rules a NEW password must meet, with whether [value] meets each.
/// The sign up screen shows these as a live checklist; [validateNewPassword]
/// uses the same facts so what the person sees and what is enforced match.
List<PasswordRule> passwordChecklist(String value) => [
  (
    label: 'At least $kMinPasswordLength characters',
    met: value.length >= kMinPasswordLength,
  ),
  (label: 'Has a letter', met: RegExp(r'[A-Za-z]').hasMatch(value)),
  (label: 'Has a number', met: RegExp(r'\d').hasMatch(value)),
];

/// Strength for the little meter: 0 = nothing typed, 1 = weak (a rule is
/// missing), 2 = okay (all rules met), 3 = strong (all rules met AND it is
/// long, mixes upper/lower case, or contains a symbol).
int passwordStrength(String value) {
  if (value.isEmpty) return 0;
  final allRulesMet = passwordChecklist(value).every((rule) => rule.met);
  if (!allRulesMet) return 1;

  final hasMixedCase =
      RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(value);
  final isLong = value.length >= 12;
  return (isLong || hasMixedCase || hasSymbol) ? 3 : 2;
}

/// Word shown next to the meter.
String passwordStrengthLabel(int strength) => switch (strength) {
  1 => 'Weak',
  2 => 'Okay',
  3 => 'Strong',
  _ => '',
};

/// Used by the SIGN UP screen when choosing a password.
String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Create a password';
  if (value.contains(RegExp(r'\s'))) return 'Password cannot contain spaces';
  if (value.length < kMinPasswordLength) {
    return 'Use at least $kMinPasswordLength characters';
  }
  final rules = passwordChecklist(value);
  if (!rules.every((rule) => rule.met)) {
    return 'Include at least one letter and one number';
  }
  return null;
}

/// "Confirm password" must repeat [original] exactly.
String? validateConfirmPassword(String? value, String original) {
  if (value == null || value.isEmpty) return 'Confirm your password';
  if (value != original) return 'Passwords do not match';
  return null;
}
