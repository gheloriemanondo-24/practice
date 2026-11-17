import 'package:campuseats/models/models.dart';
import 'package:campuseats/viewmodels/order_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Order placeOne(OrderViewModel store) {
  store.startOrder();
  return store.placeOrder();
}

void main() {
  group('order status', () {
    test('a new order starts as placed and moves forward step by step', () {
      final store = OrderViewModel();
      final order = placeOne(store);

      expect(order.status, OrderStatus.placed);
      store.advanceStatus(order);
      expect(order.status, OrderStatus.preparing);
      store.advanceStatus(order);
      expect(order.status, OrderStatus.ready);
      store.advanceStatus(order);
      expect(order.status, OrderStatus.pickedUp);

      // the end of the line, nothing more happens
      store.advanceStatus(order);
      expect(order.status, OrderStatus.pickedUp);
    });

    test('an order can only be cancelled before it is being prepared', () {
      final store = OrderViewModel();
      final first = placeOne(store);
      store.cancelOrder(first);
      expect(first.status, OrderStatus.cancelled);

      // a cancelled order cannot be moved forward
      store.advanceStatus(first);
      expect(first.status, OrderStatus.cancelled);

      final second = placeOne(store);
      store.advanceStatus(second);
      expect(store.canCancel(second), isFalse);
      store.cancelOrder(second);
      expect(second.status, OrderStatus.preparing);
    });
  });

  group('order history', () {
    test('keeps every order, newest first', () {
      final store = OrderViewModel();
      final first = placeOne(store);
      final second = placeOne(store);

      expect(store.orders, [second, first]);
      expect(store.lastOrder, second);
    });

    test('is cleared on log out', () {
      final store = OrderViewModel();
      placeOne(store);
      store.reset();

      expect(store.orders, isEmpty);
      expect(store.lastOrder, isNull);
    });
  });

  group('customers and stalls', () {
    const maria = AppUser(
      name: 'Maria Santos',
      email: 'student@campus.edu',
      password: 'x',
      role: UserRole.student,
      idNumber: '1',
    );
    const jose = AppUser(
      name: 'Jose Reyes',
      email: 'teacher@campus.edu',
      password: 'x',
      role: UserRole.teacher,
      idNumber: '2',
    );

    test('an order remembers who placed it', () {
      final store = OrderViewModel();
      store.startOrder(customer: jose);
      final order = store.placeOrder();

      expect(order.customerName, 'Jose Reyes');
      expect(order.customerEmail, 'teacher@campus.edu');
      expect(order.customerRole, UserRole.teacher);
    });

    test('each person only gets their own orders back', () {
      final store = OrderViewModel();
      store.startOrder(customer: maria);
      final mine = store.placeOrder();
      store.startOrder(customer: jose);
      final his = store.placeOrder();

      expect(store.ordersBy(maria.email), [mine]);
      expect(store.ordersBy(jose.email), [his]);
      expect(store.lastOrderBy(maria.email), mine);
      expect(store.ordersBy(null), isEmpty);
      expect(store.lastOrderBy('nobody@campus.edu'), isNull);
    });

    test('a stall sees only the orders placed at that stall', () {
      final store = OrderViewModel();
      final first = store.places[0];
      final second = store.places[1];

      store.selectPlace(first);
      store.startOrder(customer: maria);
      final atFirst = store.placeOrder();
      store.selectPlace(second);
      store.startOrder(customer: maria);
      final atSecond = store.placeOrder();

      expect(store.ordersFor(first), [atFirst]);
      expect(store.ordersFor(second), [atSecond]);
    });

    test('logging out keeps orders and stall edits for the stall to see', () {
      final store = OrderViewModel();
      store.startOrder(customer: maria);
      final order = store.placeOrder();
      store.setOpen(store.selectedPlace, false);
      store.endSession();

      expect(store.orders, [order]);
      expect(store.cart, isEmpty);
      expect(store.places.first.open, isFalse);
    });

    test('staff can decline an order until it is ready', () {
      final store = OrderViewModel();
      final waiting = placeOne(store);
      expect(store.canDecline(waiting), isTrue);
      store.declineOrder(waiting);
      expect(waiting.status, OrderStatus.cancelled);

      final cooking = placeOne(store);
      store.advanceStatus(cooking);
      expect(store.canDecline(cooking), isTrue);

      store.advanceStatus(cooking); // ready
      expect(store.canDecline(cooking), isFalse);
      store.declineOrder(cooking);
      expect(cooking.status, OrderStatus.ready);
    });
  });

  group('stall management', () {
    test('closing a stall stops orders and keeps it selected', () {
      final store = OrderViewModel();
      final stall = store.selectedPlace;
      store.setOpen(stall, false);

      expect(store.selectedPlace.open, isFalse);
      expect(store.selectedPlace.canOrder, isFalse);
      expect(store.selectedPlace.name, stall.name);
    });

    test('wait time stays between 1 and 60 minutes', () {
      final store = OrderViewModel();
      store.setWaitMinutes(store.selectedPlace, 0);
      expect(store.selectedPlace.waitMinutes, 1);
      store.setWaitMinutes(store.selectedPlace, 500);
      expect(store.selectedPlace.waitMinutes, 60);
    });

    test('dishes can be added with a price and removed', () {
      final store = OrderViewModel();
      final before = store.selectedPlace.menu.length;

      expect(store.addMenuItem(store.selectedPlace, 'Dinuguan', 70), isNull);
      expect(store.selectedPlace.menu.length, before + 1);
      expect(store.selectedPlace.menu.last.name, 'Dinuguan');
      expect(store.selectedPlace.menu.last.price, 70);

      store.removeMenuItem(store.selectedPlace, 'Dinuguan');
      expect(store.selectedPlace.menu.length, before);
    });

    test('empty, duplicate and badly priced dishes are rejected', () {
      final store = OrderViewModel();
      final existing = store.selectedPlace.menu.first.name;

      expect(store.addMenuItem(store.selectedPlace, '   ', 50), isNotNull);
      expect(
        store.addMenuItem(store.selectedPlace, existing.toUpperCase(), 50),
        isNotNull,
      );
      expect(store.addMenuItem(store.selectedPlace, 'Free', 0), isNotNull);
      expect(store.addMenuItem(store.selectedPlace, 'No price', null), isNotNull);
    });

    test('prices can be updated', () {
      final store = OrderViewModel();
      final dish = store.selectedPlace.menu.first.name;

      expect(store.setItemPrice(store.selectedPlace, dish, 99), isNull);
      expect(store.selectedPlace.menu.first.price, 99);
      expect(store.setItemPrice(store.selectedPlace, dish, -5), isNotNull);
      expect(store.selectedPlace.menu.first.price, 99);
    });

    test('a sold out dish cannot be ordered', () {
      final store = OrderViewModel();
      final dish = store.selectedPlace.menu.first.name;
      store.setItemAvailable(store.selectedPlace, dish, false);

      // new orders skip the sold out dish
      store.startOrder();
      expect(store.cart.any((l) => l.name == dish), isFalse);

      // and it cannot be added by hand either
      store.addItem(store.selectedPlace.menu.first);
      expect(store.cart.any((l) => l.name == dish), isFalse);
    });

    test('a stall with everything sold out cannot take orders', () {
      final store = OrderViewModel();
      for (final item in store.selectedPlace.menu.toList()) {
        store.setItemAvailable(store.selectedPlace, item.name, false);
      }
      expect(store.selectedPlace.canOrder, isFalse);
    });

    test('an order keeps the prices it was placed with', () {
      final store = OrderViewModel();
      store.startOrder();
      final expected = store.cart.fold<int>(0, (sum, l) => sum + l.total);
      final order = store.placeOrder();

      store.setItemPrice(
        store.selectedPlace,
        order.lines.first.name,
        order.lines.first.price + 100,
      );
      expect(order.total, expected);
      expect(order.total, greaterThan(0));
    });

    test('a stall with a one dish menu can still start an order', () {
      final store = OrderViewModel();
      final stall = store.selectedPlace;
      for (final item in stall.menu.skip(1).toList()) {
        store.removeMenuItem(store.selectedPlace, item.name);
      }

      store.startOrder();
      expect(store.cart.length, 1);
    });
  });
}
