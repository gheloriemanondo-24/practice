import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';
import 'confirmation_screen.dart';
import 'history_screen.dart';
import 'order_screen.dart';
import 'stall_management_screen.dart';
import 'stall_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.auth});

  final OrderViewModel store;
  final AuthViewModel auth;

  // clear the cart and last order, then go back to the login screen
  void _logOut() {
    store.reset();
    auth.logOut();
  }

  void _order(BuildContext context) {
    final place = store.selectedPlace;
    if (!place.canOrder) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${place.name} is closed right now.')),
        );
      return;
    }
    store.startOrder();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderScreen(store: store)),
    );
  }

  void _track(BuildContext context) {
    final order = store.lastOrder;
    if (order == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No active order yet. Place one first.')),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationScreen(order: order, store: store),
      ),
    );
  }

  void _history(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HistoryScreen(store: store)),
    );
  }

  void _manageStall(BuildContext context, String stallName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StallManagementScreen(store: store, placeName: stallName),
      ),
    );
  }

  // opens a stall's menu and details; customers can order from there
  void _viewMenu(BuildContext context, Place place, bool canOrder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StallMenuScreen(
          store: store,
          placeName: place.name,
          onOrder: canOrder
              ? () {
                  store.selectPlace(place);
                  Navigator.of(context).pop();
                  _order(context);
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final active = store.lastOrder;
            final isStaff = auth.currentUser?.role == UserRole.stallStaff;
            final stall = auth.currentUser?.stallName;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                const TopBar(),
                const SizedBox(height: 12),
                if (auth.currentUser != null)
                  _UserStrip(user: auth.currentUser!, onLogOut: _logOut),
                const SizedBox(height: 28),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Skip the line.\n'),
                      TextSpan(
                        text: 'Order ahead.',
                        style: TextStyle(color: AppColors.tomato),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pick a stall, set a pickup time, and walk straight to the '
                  'counter when it is ready.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 28),
                if (isStaff && stall != null)
                  BigButton(
                    label: 'MANAGE MY STALL',
                    onPressed: () => _manageStall(context, stall),
                  )
                else ...[
                  BigButton(
                    label: 'ORDER FOOD',
                    onPressed: () => _order(context),
                  ),
                  const SizedBox(height: 12),
                  BigButton(
                    label: 'TRACK MY ORDER',
                    kind: BigButtonKind.outline,
                    onPressed: () => _track(context),
                  ),
                  const SizedBox(height: 12),
                  BigButton(
                    label: 'ORDER HISTORY',
                    kind: BigButtonKind.outline,
                    onPressed: () => _history(context),
                  ),
                ],
                if (active != null && !isStaff) ...[
                  const SizedBox(height: 16),
                  _ActiveOrderStrip(
                    order: active,
                    onTap: () => _track(context),
                  ),
                ],
                const SizedBox(height: 36),
                const SectionLabel('Nearby locations'),
                const SizedBox(height: 10),
                for (final place in store.places)
                  _PlaceRow(
                    place: place,
                    selected: place == store.selectedPlace,
                    onTap: () => store.selectPlace(place),
                    onViewMenu: () => _viewMenu(context, place, !isStaff),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.selected,
    required this.onTap,
    required this.onViewMenu,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onViewMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected ? AppColors.tomato : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.tagline,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onViewMenu,
                  tooltip: 'View menu at ${place.name}',
                  icon: const Icon(Icons.restaurant_menu, size: 20),
                ),
                const SizedBox(width: 4),
                if (place.open)
                  WaitChip(minutes: place.waitMinutes)
                else
                  const Text(
                    'Closed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
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

class _ActiveOrderStrip extends StatelessWidget {
  const _ActiveOrderStrip({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tomatoSoft,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${order.label} at ${order.place.name}: '
                  '${order.status.label}, '
                  'pickup ${formatTime(order.pickup)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// "Kumusta, Maria" with a role badge and a log out button
class _UserStrip extends StatelessWidget {
  const _UserStrip({required this.user, required this.onLogOut});

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
