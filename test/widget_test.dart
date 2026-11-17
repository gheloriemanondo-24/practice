import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campuseats/main.dart';
import 'package:campuseats/models/models.dart';
import 'package:campuseats/viewmodels/auth_view_model.dart';
import 'package:campuseats/viewmodels/order_view_model.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // tall screen so every form field is built
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    CampusEatsApp(store: OrderViewModel(), auth: AuthViewModel()),
  );
}

Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
}

Future<void> logIn(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await typeInto(tester, 'Email', email);
  await typeInto(tester, 'Password', password);
  await tester.tap(find.text('LOG IN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app opens on the login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsNothing);
  });

  testWidgets('student can log in and place an order', (tester) async {
    await pumpApp(tester);
    await logIn(tester, email: 'student@campus.edu', password: 'student123');

    expect(find.text('Kumusta, Maria'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text("Aling Nena's Karinderya"), findsOneWidget);

    await tester.tap(find.text('ORDER FOOD'));
    await tester.pumpAndSettle();

    expect(find.text('ORDERING FROM'), findsOneWidget);
    expect(find.text('YOUR ORDER'), findsOneWidget);
    expect(find.text('Chicken Adobo with Rice'), findsOneWidget);
  });

  testWidgets('wrong password shows an error', (tester) async {
    await pumpApp(tester);
    await logIn(tester, email: 'student@campus.edu', password: 'nope-nope');

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsNothing);
  });

  testWidgets('teacher account cannot log in as a student', (tester) async {
    await pumpApp(tester);
    await logIn(tester, email: 'teacher@campus.edu', password: 'teacher123');

    expect(find.textContaining('registered as a teacher'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsNothing);
  });

  testWidgets('teacher can log in after choosing Teacher', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Teacher'));
    await tester.pump();
    await logIn(tester, email: 'teacher@campus.edu', password: 'teacher123');

    expect(find.text('Kumusta, Jose'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
  });

  testWidgets('sign up validates the form', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Create a password'), findsOneWidget);
  });

  testWidgets('new teacher can sign up and land on home', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teacher'));
    await tester.pump();
    await typeInto(tester, 'Full name', 'Ana Dela Cruz');
    await typeInto(tester, 'Faculty ID', 'FAC-9001');
    await typeInto(tester, 'Email', 'ana@campus.edu');
    await typeInto(tester, 'Password', 'secret123');
    await typeInto(tester, 'Confirm password', 'secret123');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Kumusta, Ana'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsOneWidget);
  });

  testWidgets('log out returns to the login screen', (tester) async {
    await pumpApp(tester);
    await logIn(tester, email: 'student@campus.edu', password: 'student123');

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsNothing);
  });

  testWidgets('stall staff land on the dashboard for their own stall', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Stall staff'));
    await tester.pump();
    await logIn(tester, email: 'staff@campus.edu', password: 'staff123');

    // straight to the dashboard, no customer home in between
    expect(find.text('Kumusta, Nena'), findsOneWidget);
    expect(find.text("Aling Nena's Karinderya"), findsOneWidget);
    expect(find.text('Open for orders'), findsOneWidget);
    expect(find.text('ORDER FOOD'), findsNothing);
    expect(find.text('Nearby locations'.toUpperCase()), findsNothing);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.textContaining('No orders yet'), findsOneWidget);
  });

  testWidgets('staff see orders from customers and can move them along', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrderViewModel();
    final auth = AuthViewModel();

    // Maria (student) orders from Aling Nena's, then the staff log in
    final maria = AppUser(
      name: 'Maria Santos',
      email: 'student@campus.edu',
      password: 'student123',
      role: UserRole.student,
      idNumber: '2024-00123',
    );
    store.startOrder(customer: maria);
    store.placeOrder();
    store.endSession(); // what logging out does

    await tester.pumpWidget(CampusEatsApp(store: store, auth: auth));
    await tester.tap(find.text('Stall staff'));
    await tester.pump();
    await logIn(tester, email: 'staff@campus.edu', password: 'staff123');

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Order placed'), findsOneWidget);

    await tester.tap(find.text('START PREPARING'));
    await tester.pumpAndSettle();
    expect(find.text('Being prepared'), findsOneWidget);
    expect(store.orders.first.status, OrderStatus.preparing);

    await tester.tap(find.text('MARK READY'));
    await tester.pumpAndSettle();
    expect(find.text('Ready for pickup'), findsOneWidget);
  });

  testWidgets('staff only see orders for their own stall', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrderViewModel();
    final auth = AuthViewModel();

    // an order at a different stall than the staff member's
    store.selectPlace(store.places[1]);
    store.startOrder();
    store.placeOrder();
    store.endSession();

    await tester.pumpWidget(CampusEatsApp(store: store, auth: auth));
    await tester.tap(find.text('Stall staff'));
    await tester.pump();
    await logIn(tester, email: 'staff@campus.edu', password: 'staff123');

    expect(find.text('#0001'), findsNothing);
    expect(find.textContaining('No orders yet'), findsOneWidget);
  });

  testWidgets('students cannot see stall management', (tester) async {
    await pumpApp(tester);
    await logIn(tester, email: 'student@campus.edu', password: 'student123');

    expect(find.text('MANAGE MY STALL'), findsNothing);
    expect(find.text('ORDER HISTORY'), findsOneWidget);
  });

  testWidgets('stall staff sign up must choose a stall', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stall staff'));
    await tester.pump();

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the stall you work at'), findsOneWidget);
  });
  // ---- Registration validation -------------------------------------------

  testWidgets('sign up shows field-specific errors for bad input', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await typeInto(tester, 'Full name', 'Ana');
    await typeInto(tester, 'Student ID', '123');
    await typeInto(tester, 'Email', 'not-an-email');
    await typeInto(tester, 'Password', 'abc');
    await typeInto(tester, 'Confirm password', 'xyz');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your first and last name'), findsOneWidget);
    expect(find.text('Use the format 2024-00123'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('sign up rejects an email that is already registered', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await typeInto(tester, 'Full name', 'Maria Santos');
    await typeInto(tester, 'Student ID', '2024-00123');
    await typeInto(tester, 'Email', 'student@campus.edu'); // demo account
    await typeInto(tester, 'Password', 'secret123');
    await typeInto(tester, 'Confirm password', 'secret123');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already exists'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget); // still on the form
  });

  testWidgets('switching role clears the ID field', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await typeInto(tester, 'Student ID', '2024-00123');
    await tester.tap(find.text('Teacher'));
    await tester.pump();

    final idField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Faculty ID'),
    );
    expect(idField.controller!.text, isEmpty);
  });

  testWidgets('password checklist updates while typing', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    await typeInto(tester, 'Password', 'secret123');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(3));
  });
}
