import 'package:flutter/foundation.dart';

import '../models/models.dart';

class OrderViewModel extends ChangeNotifier {
  // a copy of the sample stalls, so Stall Management can edit them
  List<Place> _places = List.of(kPlaces);
  late Place _selectedPlace = _places.first;
  List<CartLine> _cart = [];
  List<DateTime> _slots = [];
  DateTime? _pickup;
  // who is placing the current order (null in tests, shown as "Guest")
  AppUser? _customer;
  // every placed order, newest first (this is the order history)
  final List<Order> _orders = [];
  int _nextNumber = 1;

  List<Place> get places => List.unmodifiable(_places);
  Place get selectedPlace => _selectedPlace;
  List<Order> get orders => List.unmodifiable(_orders);
  // the most recent order, or null before anything was placed
  Order? get lastOrder => _orders.isEmpty ? null : _orders.first;
  List<CartLine> get cart => List.unmodifiable(_cart);
  List<DateTime> get slots => List.unmodifiable(_slots);
  DateTime? get pickup => _pickup;
  int get itemCount => _cart.fold<int>(0, (sum, line) => sum + line.qty);

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  // Called on log out. Clears the cart and selection so the next person starts
  // clean, but keeps orders and stall edits: they belong to the stalls, so a
  // stall staff member who logs in next still sees what students ordered.
  void endSession() {
    _selectedPlace = _places.first;
    _cart = [];
    _slots = [];
    _pickup = null;
    _customer = null;
    notifyListeners();
  }

  // Wipes everything, orders and stall edits included (a full demo reset).
  void reset() {
    _places = List.of(kPlaces);
    _selectedPlace = _places.first;
    _cart = [];
    _slots = [];
    _pickup = null;
    _customer = null;
    _orders.clear();
    notifyListeners();
  }

  // called when the student taps "Order food" Starts a fresh cart
  // pre-filled with the stall's first two dishes like the mockup
  // and builds fresh pickup slots
  void startOrder({AppUser? customer}) {
    _customer = customer;
    final menu = _selectedPlace.menu.where((m) => m.available);
    _cart = [for (final item in menu.take(2)) CartLine(item.name, item.price)];
    _slots = _buildSlots(_selectedPlace);
    _pickup = _slots.first;
    notifyListeners();
  }

  void changeQty(CartLine line, int delta) {
    final next = line.qty + delta;
    if (next < 1 || next > 9) return;
    line.qty = next;
    notifyListeners();
  }

  // removes line and returns the index it had, so Undo can put it back
  int removeLine(CartLine line) {
    final index = _cart.indexOf(line);
    if (index == -1) return -1;
    _cart.removeAt(index);
    notifyListeners();
    return index;
  }

  void restoreLine(int index, CartLine line) {
    if (index < 0) return;
    final at = index > _cart.length ? _cart.length : index;
    _cart.insert(at, line);
    notifyListeners();
  }

  void addItem(MenuItem item) {
    if (!item.available) return;
    for (final line in _cart) {
      if (line.name == item.name) {
        changeQty(line, 1);
        return;
      }
    }
    _cart.add(CartLine(item.name, item.price));
    notifyListeners();
  }

  void setPickup(DateTime time) {
    _pickup = time;
    notifyListeners();
  }

  Order placeOrder() {
    final order = Order(
      number: _nextNumber++,
      place: _selectedPlace,
      pickup: _pickup!,
      lines: _cart.map((l) => CartLine(l.name, l.price, l.qty)).toList(),
      placedAt: DateTime.now(),
      customerName: _customer?.name ?? 'Guest',
      customerEmail: _customer?.email,
      customerRole: _customer?.role ?? UserRole.student,
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  // ---- Order status ----

  // Moves the order to its next status (placed, preparing, ready, picked up).
  void advanceStatus(Order order) {
    final next = order.status.next;
    if (next == null || order.status == OrderStatus.cancelled) return;
    order.status = next;
    notifyListeners();
  }

  // The customer can cancel until the stall starts preparing the order.
  bool canCancel(Order order) => order.status == OrderStatus.placed;

  void cancelOrder(Order order) {
    if (!canCancel(order)) return;
    order.status = OrderStatus.cancelled;
    notifyListeners();
  }

  // Stall staff can turn an order down while it is waiting or being prepared
  // (for example when an ingredient ran out). The customer sees it cancelled.
  bool canDecline(Order order) =>
      order.status == OrderStatus.placed ||
      order.status == OrderStatus.preparing;

  void declineOrder(Order order) {
    if (!canDecline(order)) return;
    order.status = OrderStatus.cancelled;
    notifyListeners();
  }

  // orders for one stall, newest first
  List<Order> ordersFor(Place place) => [
    for (final order in _orders)
      if (order.place.name == place.name) order,
  ];

  // orders placed by one person (matched by email), newest first
  List<Order> ordersBy(String? email) => [
    for (final order in _orders)
      if (email != null && order.customerEmail == email) order,
  ];

  // that person's most recent order, or null if they have none
  Order? lastOrderBy(String? email) {
    final mine = ordersBy(email);
    return mine.isEmpty ? null : mine.first;
  }

  // ---- Stall management ----

  // Replaces a stall with an edited copy and keeps the selection on it.
  void _replacePlace(Place old, Place next) {
    final index = _places.indexOf(old);
    if (index == -1) return;
    _places = List.of(_places)..[index] = next;
    if (_selectedPlace == old) _selectedPlace = next;
    notifyListeners();
  }

  void setOpen(Place place, bool open) =>
      _replacePlace(place, place.copyWith(open: open));

  void setWaitMinutes(Place place, int minutes) {
    final clamped = minutes < 1 ? 1 : (minutes > 60 ? 60 : minutes);
    _replacePlace(place, place.copyWith(waitMinutes: clamped));
  }

  // Returns an error message, or null when the dish was added.
  String? addMenuItem(Place place, String name, int? price) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Enter a dish name';
    final priceError = _checkPrice(price);
    if (priceError != null) return priceError;
    final exists = place.menu.any(
      (m) => m.name.toLowerCase() == clean.toLowerCase(),
    );
    if (exists) return 'That dish is already on the menu';
    _replacePlace(
      place,
      place.copyWith(menu: [...place.menu, MenuItem(clean, price!)]),
    );
    return null;
  }

  // Returns an error message, or null when the price was changed.
  String? setItemPrice(Place place, String dish, int? price) {
    final error = _checkPrice(price);
    if (error != null) return error;
    _editItem(place, dish, (m) => m.copyWith(price: price));
    return null;
  }

  void setItemAvailable(Place place, String dish, bool available) =>
      _editItem(place, dish, (m) => m.copyWith(available: available));

  void removeMenuItem(Place place, String dish) {
    _replacePlace(
      place,
      place.copyWith(
        menu: [
          for (final m in place.menu)
            if (m.name != dish) m,
        ],
      ),
    );
  }

  static String? _checkPrice(int? price) {
    if (price == null) return 'Enter a price in pesos';
    if (price < 1 || price > 9999) return 'Price must be 1 to 9999 pesos';
    return null;
  }

  List<DateTime> _buildSlots(Place place) {
    final start = DateTime.now().add(Duration(minutes: place.waitMinutes));
    return [for (var i = 0; i < 5; i++) start.add(Duration(minutes: i * 15))];
  }

  void _editItem(Place place, String dish, MenuItem Function(MenuItem) edit) {
    _replacePlace(
      place,
      place.copyWith(
        menu: [for (final m in place.menu) m.name == dish ? edit(m) : m],
      ),
    );
  }
}
