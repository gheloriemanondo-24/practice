# CampusEats

Order ahead from campus food stalls. Built with Flutter (MVVM: `models`, `viewmodels`, `views`).

## Accounts

People log in or sign up as a **Student** or a **Teacher**. Accounts are kept in
memory only, so they are cleared when the app restarts. A real app would use a
server and never store plain text passwords.

Demo accounts for trying the app:

| Role    | Email               | Password     |
| ------- | ------------------- | ------------ |
| Student | student@campus.edu  | student123   |
| Teacher | teacher@campus.edu  | teacher123   |

The role selected on the login screen must match the account's role.

## Food stalls

Stalls and menus live in `kPlaces` in `lib/models/models.dart`. Most serve
Filipino meals, snacks and desserts, plus a Cebuano corner.

## Demo accounts

Stall staff also have an account type. They pick the stall they work at when
they sign up.

| Role        | Email              | Password   | Stall                    |
| ----------- | ------------------ | ---------- | ------------------------ |
| Stall staff | staff@campus.edu   | staff123   | Aling Nena's Karinderya  |

## Menus, prices and listings

Every dish has a price (in pesos) and can be marked sold out. Tap the menu icon
on a stall on the home screen to see its details and full menu, and to order
from it. Customers see prices while ordering and a total at checkout and on the
order ticket.

## Order tracking, history and stall management

- Every order has a status: placed, preparing, ready, picked up (or cancelled).
  The tracking screen shows the steps and updates live. An order can be
  cancelled until the stall starts preparing it.
- **Order history** on the home screen lists every order from this session.
- **Manage my stall** (stall staff only) lets staff open or close their stall,
  change its wait time, add or remove dishes, edit prices and availability, and
  move incoming orders through their statuses.

Like accounts, all of this is kept in memory only.
