import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets.dart';

// Campus food stall listing details: status, wait time, and the full menu with
// prices. Sold out dishes are shown but marked. [onOrder] is null for stall
// staff, who do not place orders.
class StallMenuScreen extends StatelessWidget {
  const StallMenuScreen({
    super.key,
    required this.store,
    required this.placeName,
    this.onOrder,
  });

  final OrderViewModel store;
  final String placeName;
  final VoidCallback? onOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final place = store.places.firstWhere((p) => p.name == placeName);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      TopBar(onBack: () => Navigator.of(context).pop()),
                      const SizedBox(height: 12),
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.tagline,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            place.open ? 'Open' : 'Closed',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 16),
                          if (place.open) WaitChip(minutes: place.waitMinutes),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionLabel('Menu'),
                      const SizedBox(height: 6),
                      if (place.menu.isEmpty)
                        const Text(
                          'No dishes listed yet.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      for (final item in place.menu)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: item.available
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                          subtitle: item.available
                              ? null
                              : const Text('Sold out'),
                          trailing: Text(
                            formatPrice(item.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onOrder != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: BigButton(
                      label: place.canOrder ? 'ORDER FROM HERE' : 'UNAVAILABLE',
                      onPressed: place.canOrder ? onOrder : null,
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
