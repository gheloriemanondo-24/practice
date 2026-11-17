import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';
import 'confirmation_screen.dart';

// Every order this person placed, newest first. Tap one to track it.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store, this.customerEmail});

  final OrderViewModel store;

  // whose orders to show; when null, every order is shown
  final String? customerEmail;

  void _open(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationScreen(order: order, store: store),
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
            final orders = customerEmail == null
                ? store.orders
                : store.ordersBy(customerEmail);
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                TopBar(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 12),
                const Text(
                  'Order history',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 20),
                if (orders.isEmpty)
                  const Text(
                    'No orders yet. Your past orders will show up here.',
                    style: TextStyle(fontSize: 16, color: AppColors.muted),
                  ),
                for (final order in orders)
                  _HistoryRow(order: order, onTap: () => _open(context, order)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.rule),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.label}  ${order.place.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.itemCount} items, pickup '
                        '${formatTime(order.pickup)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: order.status.isActive
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
