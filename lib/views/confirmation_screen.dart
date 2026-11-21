import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';

// Shown right after checkout and again when tracking an order from home or
// from the history. It rebuilds when the stall changes the order's status.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.order,
    required this.store,
  });

  final Order order;
  final OrderViewModel store;

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Cancel order ${order.label}?'),
        content: const Text('The stall will not prepare this order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.cancelOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final status = order.status;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      const TopBar(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            status == OrderStatus.cancelled
                                ? Icons.cancel_outlined
                                : Icons.check_circle,
                            color: AppColors.green,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              status.label,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pickup at ${formatTime(order.pickup)}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (status == OrderStatus.cancelled)
                        const ErrorBanner('This order was cancelled.')
                      else
                        _StatusTracker(status: status),
                      const SizedBox(height: 24),
                      _Ticket(order: order),
                      const SizedBox(height: 16),
                      const Text(
                        'Show this number at the counter when you arrive.',
                        style: TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      if (store.canCancel(order)) ...[
                        BigButton(
                          label: 'CANCEL ORDER',
                          kind: BigButtonKind.outline,
                          onPressed: () => _cancel(context),
                        ),
                        const SizedBox(height: 12),
                      ],
                      BigButton(
                        label: 'DONE',
                        kind: BigButtonKind.dark,
                        onPressed: () => Navigator.of(context).pop(),
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

// the steps an order goes through, with the current one marked
class _StatusTracker extends StatelessWidget {
  const _StatusTracker({required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUp,
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Order status'),
        const SizedBox(height: 10),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  i < current
                      ? Icons.check_circle
                      : i == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: i <= current ? AppColors.ink : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Text(
                  _steps[i].label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                    color: i <= current ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionLabel('Order number')),
                    Text(
                      order.place.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.label,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DashedDivider(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Pickup'),
                const SizedBox(height: 4),
                Text(
                  formatTime(order.pickup),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Items'),
                const SizedBox(height: 6),
                for (final line in order.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${line.qty} x ${line.name}  '
                      '${formatPrice(line.total)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Total ${formatPrice(order.total)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
