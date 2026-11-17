import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';

// What a stall staff account sees for their own stall: open or closed, wait
// time, menu (add or edit dishes, prices and availability) and incoming orders
// that can be moved through their statuses.
//
// The stall is looked up by name on every rebuild because editing replaces
// the Place object.
class StallManagementScreen extends StatefulWidget {
  const StallManagementScreen({
    super.key,
    required this.store,
    required this.placeName,
  });

  final OrderViewModel store;
  final String placeName;

  @override
  State<StallManagementScreen> createState() => _StallManagementScreenState();
}

class _StallManagementScreenState extends State<StallManagementScreen> {
  final _dishController = TextEditingController();
  final _priceController = TextEditingController();
  String? _dishError;

  OrderViewModel get _store => widget.store;

  @override
  void dispose() {
    _dishController.dispose();
    _priceController.dispose();
    super.dispose();
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
    final error = _store.setItemPrice(place, item.name, int.tryParse(text.trim()));
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final place = _store.places.firstWhere(
              (p) => p.name == widget.placeName,
            );
            final orders = _store.ordersFor(place);
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                TopBar(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 12),
                const SectionLabel('Managing'),
                const SizedBox(height: 4),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open for orders'),
                  value: place.open,
                  onChanged: (v) => _store.setOpen(place, v),
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Wait time')),
                    IconButton(
                      tooltip: 'Less wait',
                      onPressed: () =>
                          _store.setWaitMinutes(place, place.waitMinutes - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${place.waitMinutes} min',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'More wait',
                      onPressed: () =>
                          _store.setWaitMinutes(place, place.waitMinutes + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionLabel('Menu'),
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
                          onChanged: (v) =>
                              _store.setItemAvailable(place, item.name, v),
                        ),
                        IconButton(
                          tooltip: 'Edit price of ${item.name}',
                          onPressed: () => _editPrice(place, item),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Remove ${item.name}',
                          onPressed: () =>
                              _store.removeMenuItem(place, item.name),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
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
                const SizedBox(height: 28),
                const SectionLabel('Incoming orders'),
                const SizedBox(height: 10),
                if (orders.isEmpty)
                  const Text(
                    'No orders for this stall yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                for (final order in orders)
                  _StallOrderRow(order: order, store: _store),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StallOrderRow extends StatelessWidget {
  const _StallOrderRow({required this.order, required this.store});

  final Order order;
  final OrderViewModel store;

  // the button label for moving the order forward
  static String _action(OrderStatus next) => switch (next) {
    OrderStatus.preparing => 'START PREPARING',
    OrderStatus.ready => 'MARK READY',
    OrderStatus.pickedUp => 'MARK PICKED UP',
    _ => 'NEXT',
  };

  @override
  Widget build(BuildContext context) {
    final next = order.status.next;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                order.status.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pickup ${formatTime(order.pickup)}, ${formatPrice(order.total)}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          for (final line in order.lines) Text('${line.qty} x ${line.name}'),
          if (next != null && order.status.isActive) ...[
            const SizedBox(height: 12),
            BigButton(
              label: _action(next),
              kind: BigButtonKind.dark,
              onPressed: () => store.advanceStatus(order),
            ),
          ],
        ],
      ),
    );
  }
}
