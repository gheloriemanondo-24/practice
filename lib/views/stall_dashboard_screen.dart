import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';

// The home screen for stall staff. It opens on the stall they picked when they
// registered (AppUser.stallName) and has two tabs:
//
//   Orders  incoming orders from students and teachers, with each order's
//           status, moved forward (or declined) by the stall.
//   Menu    open or close the stall, wait time, dishes, prices, sold out.
//
// The stall is looked up by name on every rebuild because editing replaces the
// Place object. Customers see every change right away: their tracking screen
// listens to the same OrderViewModel.

enum _Tab { orders, menu }

// which orders the list shows
enum _OrderFilter {
  active('Active'),
  fresh('New'),
  preparing('Preparing'),
  ready('Ready'),
  done('Done');

  const _OrderFilter(this.label);
  final String label;

  bool matches(Order order) => switch (this) {
    active => order.status.isActive,
    fresh => order.status == OrderStatus.placed,
    preparing => order.status == OrderStatus.preparing,
    ready => order.status == OrderStatus.ready,
    done => !order.status.isActive,
  };
}

class StallDashboardScreen extends StatefulWidget {
  const StallDashboardScreen({
    super.key,
    required this.store,
    required this.auth,
    required this.stallName,
  });

  final OrderViewModel store;
  final AuthViewModel auth;

  // the stall chosen at registration
  final String stallName;

  @override
  State<StallDashboardScreen> createState() => _StallDashboardScreenState();
}

class _StallDashboardScreenState extends State<StallDashboardScreen> {
  final _dishController = TextEditingController();
  final _priceController = TextEditingController();
  String? _dishError;
  _Tab _tab = _Tab.orders;
  _OrderFilter _filter = _OrderFilter.active;

  OrderViewModel get _store => widget.store;

  @override
  void dispose() {
    _dishController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _logOut() {
    _store.endSession();
    widget.auth.logOut();
  }

  void _addDish(Place place) {
    final error = _store.addMenuItem(
      place,
      _dishController.text,
      int.tryParse(_priceController.text.trim()),
    );
    setState(() => _dishError = error);
    if (error == null) {
      _dishController.clear();
      _priceController.clear();
    }
  }

  Future<void> _editPrice(Place place, MenuItem item) async {
    final controller = TextEditingController(text: '${item.price}');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Price of ${item.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price in pesos'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return;
    final error = _store.setItemPrice(
      place,
      item.name,
      int.tryParse(text.trim()),
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _decline(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Decline order ${order.label}?'),
        content: Text(
          '${order.customerName} will see this order as cancelled. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.declineOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final place = _store.places
                .where((p) => p.name == widget.stallName)
                .firstOrNull;
            if (place == null) return _MissingStall(onLogOut: _logOut);

            final orders = _store.ordersFor(place);
            final newCount = orders
                .where((o) => o.status == OrderStatus.placed)
                .length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                const TopBar(),
                const SizedBox(height: 4),
                if (widget.auth.currentUser != null)
                  UserStrip(user: widget.auth.currentUser!, onLogOut: _logOut),
                const SizedBox(height: 24),
                const SectionLabel('Your stall'),
                const SizedBox(height: 4),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.tagline,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                _StallStatusCard(store: _store, place: place),
                const SizedBox(height: 20),
                _TabSwitch(
                  tab: _tab,
                  newOrders: newCount,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: 20),
                if (_tab == _Tab.orders)
                  ..._ordersTab(orders)
                else
                  ..._menuTab(place),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Orders tab ----

  List<Widget> _ordersTab(List<Order> orders) {
    final shown = orders.where(_filter.matches).toList();
    // the kitchen queue: whoever wants their food first comes first
    if (_filter != _OrderFilter.done) {
      shown.sort((a, b) => a.pickup.compareTo(b.pickup));
    }
    final collected = orders
        .where((o) => o.status == OrderStatus.pickedUp)
        .fold<int>(0, (sum, o) => sum + o.total);
    final pickedUp = orders
        .where((o) => o.status == OrderStatus.pickedUp)
        .length;

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in _OrderFilter.values)
            _FilterChip(
              label: '${f.label} (${orders.where(f.matches).length})',
              selected: f == _filter,
              onTap: () => setState(() => _filter = f),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _emptyMessage(orders),
            style: const TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ),
      for (final order in shown)
        _StallOrderCard(
          order: order,
          canDecline: _store.canDecline(order),
          onAdvance: () => _store.advanceStatus(order),
          onDecline: () => _decline(order),
        ),
      if (pickedUp > 0) ...[
        const SizedBox(height: 8),
        Text(
          'Collected so far: ${formatPrice(collected)} from '
          '$pickedUp picked up ${pickedUp == 1 ? 'order' : 'orders'}',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ],
    ];
  }

  String _emptyMessage(List<Order> orders) {
    if (orders.isEmpty) {
      return 'No orders yet. New orders from students and teachers '
          'will show up here.';
    }
    return switch (_filter) {
      _OrderFilter.active => 'Nothing in progress right now.',
      _OrderFilter.fresh => 'No new orders waiting.',
      _OrderFilter.preparing => 'Nothing is being prepared.',
      _OrderFilter.ready => 'No orders waiting for pickup.',
      _OrderFilter.done => 'No finished or cancelled orders yet.',
    };
  }

  // ---- Menu tab ----

  List<Widget> _menuTab(Place place) {
    final soldOut = place.menu.where((m) => !m.available).length;
    return [
      SectionLabel(
        'Menu  ${place.menu.length} dishes'
        '${soldOut > 0 ? ', $soldOut sold out' : ''}',
      ),
      const SizedBox(height: 6),
      for (final item in place.menu)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name),
          subtitle: Text(
            '${formatPrice(item.price)}  '
            '${item.available ? 'Available' : 'Sold out'}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: item.available,
                onChanged: (v) => _store.setItemAvailable(place, item.name, v),
              ),
              IconButton(
                tooltip: 'Edit price of ${item.name}',
                onPressed: () => _editPrice(place, item),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Remove ${item.name}',
                onPressed: () => _store.removeMenuItem(place, item.name),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      const SectionLabel('Add a dish'),
      const SizedBox(height: 8),
      TextField(
        controller: _dishController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: 'New dish'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addDish(place),
        decoration: InputDecoration(
          labelText: 'Price in pesos',
          errorText: _dishError,
          suffixIcon: IconButton(
            tooltip: 'Add dish',
            onPressed: () => _addDish(place),
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    ];
  }
}

// open or closed, and how long customers should expect to wait
class _StallStatusCard extends StatelessWidget {
  const _StallStatusCard({required this.store, required this.place});

  final OrderViewModel store;
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              place.open ? 'Open for orders' : 'Closed',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              place.open
                  ? 'Students and teachers can order from you'
                  : 'Customers cannot place new orders',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            value: place.open,
            onChanged: (v) => store.setOpen(place, v),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Wait time',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Less wait',
                onPressed: () =>
                    store.setWaitMinutes(place, place.waitMinutes - 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${place.waitMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                tooltip: 'More wait',
                onPressed: () =>
                    store.setWaitMinutes(place, place.waitMinutes + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Orders | Menu, with a count of new orders so they are hard to miss
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({
    required this.tab,
    required this.newOrders,
    required this.onChanged,
  });

  final _Tab tab;
  final int newOrders;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabOption(
            label: 'Orders',
            icon: Icons.receipt_long_outlined,
            badge: newOrders,
            selected: tab == _Tab.orders,
            onTap: () => onChanged(_Tab.orders),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabOption(
            label: 'Menu',
            icon: Icons.restaurant_menu,
            selected: tab == _Tab.menu,
            onTap: () => onChanged(_Tab.menu),
          ),
        ),
      ],
    );
  }
}

class _TabOption extends StatelessWidget {
  const _TabOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge new' : label,
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge new',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? AppColors.ink : AppColors.rule),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.paper : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// One incoming order: who it is for, what they want, when, and its status.
class _StallOrderCard extends StatelessWidget {
  const _StallOrderCard({
    required this.order,
    required this.canDecline,
    required this.onAdvance,
    required this.onDecline,
  });

  final Order order;
  final bool canDecline;
  final VoidCallback onAdvance;
  final VoidCallback onDecline;

  // the button label for moving the order forward
  static String _action(OrderStatus next) => switch (next) {
    OrderStatus.preparing => 'START PREPARING',
    OrderStatus.ready => 'MARK READY',
    OrderStatus.pickedUp => 'MARK PICKED UP',
    _ => 'NEXT',
  };

  // an icon as well as words, so the status never relies on colour alone
  static IconData _icon(OrderStatus status) => switch (status) {
    OrderStatus.placed => Icons.notifications_active_outlined,
    OrderStatus.preparing => Icons.local_fire_department_outlined,
    OrderStatus.ready => Icons.check_circle_outline,
    OrderStatus.pickedUp => Icons.done_all,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final next = order.status.next;
    final active = order.status.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: order.status == OrderStatus.placed
              ? AppColors.ink
              : AppColors.rule,
          width: order.status == OrderStatus.placed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Icon(
                _icon(order.status),
                size: 18,
                color: active ? AppColors.ink : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                order.status.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(Icons.person_outline, size: 18),
              Text(
                order.customerName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tomatoSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(
                  order.customerRole.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ordered ${formatTime(order.placedAt)}  |  '
            'Pickup ${formatTime(order.pickup)}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          const DashedDivider(),
          const SizedBox(height: 10),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(child: Text('${line.qty} x ${line.name}')),
                  Text(
                    formatPrice(line.total),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatPrice(order.total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (next != null && active) ...[
            const SizedBox(height: 14),
            BigButton(
              label: _action(next),
              kind: BigButtonKind.dark,
              onPressed: onAdvance,
            ),
            if (canDecline) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: onDecline,
                  child: const Text('Decline order'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// shown if the stall on the account no longer exists, so staff are never stuck
class _MissingStall extends StatelessWidget {
  const _MissingStall({required this.onLogOut});

  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ErrorBanner(
            'We could not find the stall linked to this account. '
            'Log out and ask an admin to check your stall.',
          ),
          const SizedBox(height: 16),
          BigButton(
            label: 'LOG OUT',
            kind: BigButtonKind.outline,
            onPressed: onLogOut,
          ),
        ],
      ),
    );
  }
}
