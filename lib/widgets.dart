import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'models/models.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CampusEats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(width: 3),
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: SizedBox(
            width: 7,
            height: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tomato,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// back arrow on the left (when given), wordmark on the right
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
            ),
          const Spacer(),
          const Wordmark(),
        ],
      ),
    );
  }
}

// small spaced-out caps label above a block of content
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.muted,
      ),
    );
  }
}

// wait time as a dot plus text, so colour is never the only signal
class WaitChip extends StatelessWidget {
  const WaitChip({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = minutes <= 5 ? AppColors.green : AppColors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$minutes min wait',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

enum BigButtonKind { primary, dark, outline }

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BigButtonKind.primary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BigButtonKind kind;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final outlined = kind == BigButtonKind.outline;
    final background = switch (kind) {
      BigButtonKind.primary => AppColors.tomato,
      BigButtonKind.dark => AppColors.ink,
      BigButtonKind.outline => Colors.transparent,
    };
    final foreground = kind == BigButtonKind.dark
        ? AppColors.paper
        : kind == BigButtonKind.outline
        ? AppColors.ink
        : Colors.white;
    final spinner = onPressed == null ? AppColors.muted : foreground;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: outlined
              ? Colors.transparent
              : AppColors.rule,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: outlined
                ? const BorderSide(color: AppColors.ink, width: 1.5)
                : BorderSide.none,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: spinner,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

// a row of short dashes, like the tear line on a ticket
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: 5,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.muted),
              ),
            ),
          ),
        );
      },
    );
  }
}

// big options: Student, Teacher or Stall staff
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  static const _icons = {
    UserRole.student: Icons.school_outlined,
    UserRole.teacher: Icons.badge_outlined,
    UserRole.stallStaff: Icons.storefront_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final role in UserRole.values) ...[
          if (role != UserRole.values.first) const SizedBox(width: 10),
          Expanded(
            child: _RoleOption(
              role: role,
              icon: _icons[role]!,
              selected: selected == role,
              onTap: enabled ? () => onChanged(role) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: role.label,
      child: Material(
        color: selected ? AppColors.card : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.rule,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: selected ? AppColors.ink : AppColors.muted),
                const SizedBox(height: 6),
                Text(
                  role.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// a short error message shown above a form's button
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.removeBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.3))),
        ],
      ),
    );
  }
}

// "Kumusta, Maria" with a role badge and a log out button
class UserStrip extends StatelessWidget {
  const UserStrip({super.key, required this.user, required this.onLogOut});

  final AppUser user;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                'Kumusta, ${user.firstName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tomatoSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(
                  user.role.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onLogOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Log out'),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
