import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';
import 'confirmation_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.store});

  final OrderViewModel store;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _placing = false;

  OrderViewModel get _store => widget.store;

  Future<void> _pickTime() async {
    final chosen = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) => _PickupSheet(
        slots: _store.slots,
        selected: _store.pickup,
      ),
    );
    if (chosen != null) _store.setPickup(chosen);
  }

  Future<void> _addItem() async {
    final chosen = await showModalBottomSheet<MenuItem>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) => _MenuSheet(
        place: _store.selectedPlace,
        cart: _store.cart,
      ),
    );
    if (chosen != null) _store.addItem(chosen);
  }

  void _remove(CartLine line) {
    final index = _store.removeLine(line);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${line.name} removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _store.restoreLine(index, line),
          ),
        ),
      );
  }

  Future<void> _confirm() async {
    setState(() => _placing = true);
    // Stands in for the call to the stall's server.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final order = _store.placeOrder();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationScreen(order: order, store: _store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final place = _store.selectedPlace;
            final cart = _store.cart;
            final pickup = _store.pickup!;
            final count = _store.itemCount;
            final total = cart.fold<int>(0, (sum, l) => sum + l.total);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      TopBar(
                        onBack:
                            _placing ? null : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 20),
                      const SectionLabel('Ordering from'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          WaitChip(minutes: place.waitMinutes),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const SectionLabel('Pickup time'),
                      const SizedBox(height: 8),
                      _PickupField(
                        time: pickup,
                        onTap: _placing ? null : _pickTime,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(child: SectionLabel('Your order')),
                          TextButton.icon(
                            onPressed: _placing ? null : _addItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add item'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.tomato,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Your order is empty. Tap Add item to pick '
                            'something from the menu.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      for (final line in cart)
                        _CartRow(
                          key: ValueKey(line.name),
                          line: line,
                          enabled: !_placing,
                          onMinus: () => _store.changeQty(line, -1),
                          onPlus: () => _store.changeQty(line, 1),
                          onRemoved: () => _remove(line),
                        ),
                      if (cart.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Swipe an item left to remove it.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    border: Border(top: BorderSide(color: AppColors.rule)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$count ${count == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            'Pickup ${formatTime(pickup)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            formatPrice(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BigButton(
                        label: _placing ? 'PLACING ORDER' : 'CONFIRM ORDER',
                        busy: _placing,
                        onPressed: (cart.isEmpty || _placing) ? null : _confirm,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PickupField extends StatelessWidget {
  const _PickupField({required this.time, required this.onTap});

  final DateTime time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTime(time),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Ready in about ${minutesUntil(time)} min',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    super.key,
    required this.line,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
    required this.onRemoved,
  });

  final CartLine line;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss-${line.name}'),
        direction:
            enabled ? DismissDirection.endToStart : DismissDirection.none,
        onDismissed: (_) => onRemoved(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.tomato,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REMOVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.rule),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${formatPrice(line.price)} each',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: (enabled && line.qty > 1) ? onMinus : null,
                tooltip: 'Fewer ${line.name}',
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '${line.qty}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: (enabled && line.qty < 9) ? onPlus : null,
                tooltip: 'More ${line.name}',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupSheet extends StatelessWidget {
  const _PickupSheet({required this.slots, required this.selected});

  final List<DateTime> slots;
  final DateTime? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Choose a pickup time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final slot in slots)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      formatTime(slot),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('Ready in about ${minutesUntil(slot)} min'),
                    trailing: slot == selected
                        ? const Icon(Icons.check, color: AppColors.tomato)
                        : null,
                    onTap: () => Navigator.of(context).pop(slot),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.place, required this.cart});

  final Place place;
  final List<CartLine> cart;

  @override
  Widget build(BuildContext context) {
    final inCart = {for (final line in cart) line.name: line.qty};

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Menu at ${place.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in place.menu)
                  ListTile(
                    enabled: item.available,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: !item.available
                        ? const Text('Sold out')
                        : inCart.containsKey(item.name)
                        ? Text('In your order: ${inCart[item.name]}')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatPrice(item.price),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (item.available) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.add_circle_outline),
                        ],
                      ],
                    ),
                    onTap: item.available
                        ? () => Navigator.of(context).pop(item)
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
