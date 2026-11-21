import 'dart:math' as math;

// who is using the app
enum UserRole {
  student,
  teacher,
  stallStaff;

  String get label => switch (this) {
    student => 'Student',
    teacher => 'Teacher',
    stallStaff => 'Stall staff',
  };

  // what the ID field is called on the sign up form
  String get idLabel => switch (this) {
    student => 'Student ID',
    teacher => 'Faculty ID',
    stallStaff => 'Staff ID',
  };

  // students and teachers order food, stall staff run a stall
  bool get isCustomer => this != stallStaff;
}

// a registered account (kept in memory only, see AuthViewModel)
class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.idNumber,
    this.stallName,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String idNumber;

  // the stall a stall staff account runs (null for students and teachers)
  final String? stallName;

  String get firstName => name.trim().split(' ').first;
}

// one dish on a stall's menu. The price is in whole pesos.
class MenuItem {
  const MenuItem(this.name, this.price, {this.available = true});

  final String name;
  final int price;

  // stall staff can mark a dish as sold out
  final bool available;

  MenuItem copyWith({int? price, bool? available}) {
    return MenuItem(
      name,
      price ?? this.price,
      available: available ?? this.available,
    );
  }
}

// food stall students and teachers can order from
class Place {
  const Place({
    required this.name,
    required this.tagline,
    required this.waitMinutes,
    required this.menu,
    this.open = true,
  });

  final String name;

  // short description shown under the stall name
  final String tagline;
  final int waitMinutes;
  final List<MenuItem> menu;

  // stalls can be closed from Stall Management
  final bool open;

  // people can only order from an open stall that has something on the menu
  bool get canOrder => open && menu.any((m) => m.available);

  Place copyWith({int? waitMinutes, List<MenuItem>? menu, bool? open}) {
    return Place(
      name: name,
      tagline: tagline,
      waitMinutes: waitMinutes ?? this.waitMinutes,
      menu: menu ?? this.menu,
      open: open ?? this.open,
    );
  }
}

// sample data A real app would load this from a server
const List<Place> kPlaces = [
  Place(
    name: "Aling Nena's Karinderya",
    tagline: 'Ulam and rice meals',
    waitMinutes: 6,
    menu: [
      MenuItem('Chicken Adobo with Rice', 85),
      MenuItem('Pork Sinigang', 95),
      MenuItem('Tapsilog', 80),
      MenuItem('Longsilog', 80),
      MenuItem('Sisig with Rice', 90),
      MenuItem('Lechon Kawali with Rice', 95),
      MenuItem('Pancit Canton', 50),
    ],
  ),
  Place(
    name: 'Meryenda ni Lola',
    tagline: 'Traditional Filipino snacks',
    waitMinutes: 4,
    menu: [
      MenuItem('Banana Cue', 20),
      MenuItem('Turon', 25),
      MenuItem('Kamote Cue', 20),
      MenuItem('Puto Cheese', 15),
      MenuItem('Bibingka', 35),
      MenuItem('Suman with Sikwate', 40),
      MenuItem('Maruya', 25),
    ],
  ),
  Place(
    name: 'Tusok-Tusok Corner',
    tagline: 'Filipino street food',
    waitMinutes: 7,
    menu: [
      MenuItem('Fishball', 20),
      MenuItem('Kikiam', 20),
      MenuItem('Kwek-Kwek', 25),
      MenuItem('Isaw', 25),
      MenuItem('Betamax', 25),
      MenuItem('Siomai', 30),
      MenuItem('Sago at Gulaman', 25),
    ],
  ),
  Place(
    name: 'Lugaw at Goto Station',
    tagline: 'Hot rice porridge and comfort bowls',
    waitMinutes: 5,
    menu: [
      MenuItem('Goto', 50),
      MenuItem('Lugaw with Egg', 40),
      MenuItem('Arroz Caldo', 45),
      MenuItem('Tokwa at Baboy', 55),
      MenuItem('Mami', 60),
      MenuItem('Pandesal with Keso', 30),
    ],
  ),
  Place(
    name: 'Halo-Halo Hub',
    tagline: 'Cold desserts and drinks',
    waitMinutes: 3,
    menu: [
      MenuItem('Halo-Halo', 70),
      MenuItem('Mais con Yelo', 45),
      MenuItem('Buko Pandan', 50),
      MenuItem('Leche Flan', 40),
      MenuItem('Ube Cheese Pandesal', 35),
      MenuItem('Fresh Buko Juice', 40),
    ],
  ),
  Place(
    name: 'Puso at Ngohiong Corner',
    tagline: 'Cebuano favorites',
    waitMinutes: 8,
    menu: [
      MenuItem('Ngohiong', 35),
      MenuItem('Puso (Hanging Rice)', 10),
      MenuItem('Lechon Cebu with Puso', 95),
      MenuItem('Siomai sa Tisa', 40),
      MenuItem('Budbud Kabog', 30),
      MenuItem('Danggit with Rice', 75),
    ],
  ),
  Place(
    name: 'BURP',
    tagline: 'Burgers and rice meals',
    waitMinutes: 8,
    menu: [
      MenuItem('Chicken Burger', 75),
      MenuItem('Chicken Fillet with Rice', 85),
      MenuItem('Crinkle Fries', 50),
      MenuItem('Iced Tea', 30),
    ],
  ),
  Place(
    name: 'Library Cafe',
    tagline: 'Sandwiches and coffee',
    waitMinutes: 3,
    menu: [
      MenuItem('Tuna Sandwich', 60),
      MenuItem('Iced Coffee', 65),
      MenuItem('Fruit Cup', 45),
      MenuItem('Blueberry Muffin', 55),
    ],
  ),
];

// one row in the cart: an item name, its price each, and how many
class CartLine {
  CartLine(this.name, this.price, [this.qty = 1]);

  final String name;
  final int price;
  int qty;

  int get total => price * qty;
}

// where an order is in its life, from placed to picked up
enum OrderStatus {
  placed,
  preparing,
  ready,
  pickedUp,
  cancelled;

  String get label => switch (this) {
    placed => 'Order placed',
    preparing => 'Being prepared',
    ready => 'Ready for pickup',
    pickedUp => 'Picked up',
    cancelled => 'Order cancelled',
  };

  // still in progress (not picked up and not cancelled)
  bool get isActive => this != pickedUp && this != cancelled;

  // the next status the stall can move the order to, or null at the end
  OrderStatus? get next => switch (this) {
    placed => preparing,
    preparing => ready,
    ready => pickedUp,
    pickedUp => null,
    cancelled => null,
  };
}

// a placed order lines are a snapshot, so later cart edits do not change it.
// Only the status changes after the order is placed (see OrderViewModel).
class Order {
  Order({
    required this.number,
    required this.place,
    required this.pickup,
    required this.lines,
    required this.placedAt,
    this.customerName = 'Guest',
    this.customerEmail,
    this.customerRole = UserRole.student,
  });

  final int number;
  final Place place;
  final DateTime pickup;
  final List<CartLine> lines;
  final DateTime placedAt;

  // who ordered, so the stall can see it and customers only see their own
  final String customerName;
  final String? customerEmail;
  final UserRole customerRole;
  OrderStatus status = OrderStatus.placed;

  String get label => '#${number.toString().padLeft(4, '0')}';

  int get itemCount => lines.fold<int>(0, (sum, line) => sum + line.qty);

  int get total => lines.fold<int>(0, (sum, line) => sum + line.total);
}

// "₱85"
String formatPrice(int pesos) => '\u20B1$pesos';

//12-hour clock, example "12:40 PM"
String formatTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

// whole minutes from now until [t], never less than 1
int minutesUntil(DateTime t) {
  return math.max(1, t.difference(DateTime.now()).inMinutes);
}
