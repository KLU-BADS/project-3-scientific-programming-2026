# Loading Vehicle Booking System

A system to book loading vehicles, share unused vehicle capacity with other users, and track bookings by role (client, admin, vehicle operator).

## 1. Actors

| Actor | Description |
|---|---|
| Guest | Anyone who opens the app before logging in. Can only see the menu, login, or sign up. |
| Client / Driver | A registered user who books vehicles. If their role is "Driver", they also pick a vehicle during sign up. |
| Admin | Has every client permission, plus one extra feature: viewing all bookings in the system. |
| Vehicle Operator | Only sees the bookings assigned to them. No booking or admin rights. |

## 2. Feature access by role

| Feature | Client / Driver | Admin | Vehicle Operator |
|---|---|---|---|
| Login / Sign up | Yes | Yes | Yes |
| Book loading vehicle | Yes | Yes | No |
| List loading vehicle with remaining capacity | Yes | Yes | No |
| View previous bookings | Yes | Yes | No |
| Cancel booking | Yes | Yes | No |
| Show all bookings (system-wide) | No | Yes | No |
| View assigned booking | No | No | Yes |

Admin is a superset of the Client role, plus the "show all bookings" feature.

## 3. Detailed flow

### Step 1 — Menu
The user opens the app and sees two options: **Login** or **Sign up**.

### Step 2 — Sign up
The user enters:
- Office address
- Name
- Username
- Role (Client, Driver, Admin, or Vehicle Operator)
- Password

If the role is **Driver**, the system also asks them to pick a vehicle from a list of available vehicles.

Once sign up is complete, the user is taken to Login.

### Step 3 — Login
The user logs in with their username and password. The system checks their stored role and decides what to show next.

### Step 4 — Role-based dashboard
- **Client / Driver** sees: Book loading vehicle, List loading vehicle with remaining capacity, View previous bookings, Cancel booking.
- **Admin** sees everything a Client sees, plus: Show all bookings.
- **Vehicle Operator** sees only: their assigned booking.

### Step 5 — Book loading vehicle
Available to Client, Driver, and Admin. The user enters, in order:
1. Number of pallets
2. Destination
3. Type of goods
4. Pickup time (a time range)
5. Delivery time (a time range)
6. Whether to list this booking's remaining capacity so other users can book it

### Step 6 — Capacity match check
After Step 5, the system checks if any existing vehicle has remaining capacity that matches the request.

- **If a match is found**, the user sees two options:
  - Book the existing vehicle's remaining capacity (shows pallets available, price, and expected delivery time)
  - Book a new vehicle instead
- **If no match is found**, the system moves straight to booking a new vehicle.

### Step 7 — Confirmation
The booking is confirmed and saved. This ends the flow.
