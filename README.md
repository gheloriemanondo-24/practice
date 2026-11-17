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

## Order tracking and history

- Every order has a status: placed, preparing, ready, picked up (or cancelled).
  The tracking screen shows the steps and updates live. An order can be
  cancelled until the stall starts preparing it.
- **Order history** on the home screen lists the orders the logged in person
  has placed.

## Stall staff dashboard

Stall staff skip the ordering home and land on a dashboard for the stall they
chose when they signed up (`AppUser.stallName`). It has:

- **Stall status:** open or close the stall and set its wait time. Closed stalls
  cannot take new orders.
- **Orders tab:** incoming orders from students and teachers, each showing who
  ordered, the items, the total, the pickup time and the current status. Filter
  by Active, New, Preparing, Ready or Done. Staff move an order forward (start
  preparing, mark ready, mark picked up) or decline it while it is waiting or
  being prepared. Customers see every change on their tracking screen.
- **Menu tab:** add or remove dishes, edit prices, mark dishes sold out.

Staff only ever see orders for their own stall.

## Data

Accounts, orders and stall edits are kept in memory only, so they are cleared
when the app restarts. Logging out keeps orders and stall edits (so a stall can
log in after a student orders), but a real app would store them on a server so
stall staff see new orders from other phones.
