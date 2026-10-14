# Collaborative Logistics.jl

<!-- DO NOT EDIT BELOW -->
[![Tests](../../actions/workflows/tests.yml/badge.svg)](../../actions/workflows/tests.yml)
[![Documentation](../../actions/workflows/docs.yml/badge.svg)](../../actions/workflows/docs.yml)
<!-- DO NOT EDIT ABOVE -->


## Overview

<!-- DESCRIBE PROJECT PURPOSE BELOW -->
The project is a collaborative logistics platform designed to help companies book and share loading vehicles more efficiently. Users can request vehicle capacity by providing details such as the number of pallets, destination, goods type, and pickup and delivery time windows. The system checks whether an existing vehicle has sufficient unused capacity and whether the shipment can be added to its route. If a suitable match is found, the user can share the available capacity; otherwise, a new vehicle can be booked. The platform supports different user roles, including clients, drivers, administrators, and vehicle operators, with access to features based on their roles. By combining shipments and making better use of available vehicle capacity, the system aims to reduce unnecessary trips and transportation costs while improving logistics efficiency.
<!-- DESCRIBE PROJECT PURPOSE ABOVE  -->

## Features × Developers

| Feature / responsibility | Developer(s) |
|---|---|
| Feasibility checks for Company B bookings | Luh Gede Mirah Semarandhanu, Rishi Ram |
| Fetch distance API research and route distance integration | Luh Gede Mirah Semarandhanu, Rishi Ram |
| Detour calculations | Rishi Ram |
| Vehicle flow, add/get operations, and authentication | Rishi Harpreet Singh Jagdev |
| Cost calculation, business flow, market research, and pricing | Valeria Rendon Corredor |
| Technical architecture, database design, menu flow, and agile task coordination | Arth Gupta |

## Getting started

<!-- DO NOT EDIT BELOW -->
Clone the repository and start Julia in the project folder:

```bash
git clone https://github.com/KLU-BADS/project-3-scientific-programming-2026.git
cd project-3-scientific-programming-2026
julia --project=.
```
<!-- DO NOT EDIT ABOVE -->


<!-- DESCRIBE THE ESSENTIAL USAGE BELOW -->
Once the package is cloned you can run:

```julia
using Project3

julia --compiled-modules=no main.jl
```
to run program
<!-- DESCRIBE THE ESSENTIAL USAGE ABOVE -->

## Tests

<!-- DO NOT EDIT BELOW -->
Tests are run automatically on GitHub for every push to `main` and on every pull request.

> [!TIP]
> To run the tests locally, run
> ```bash
> julia --project=. -e 'using Pkg; Pkg.test()'
> ```
 
<!-- DO NOT EDIT ABOVE -->


## Documentation

<!-- DO NOT EDIT BELOW -->
The [online documentation](https://klu-bads.github.io/project-3-scientific-programming-2026/) is automatically built and published to GitHub Pages on every push to `main`.

> [!TIP]
> To build the documentation locally, run
> ```bash
> julia --project=docs docs/make.jl
> ```
> and open `docs/build/index.html` in a browser.
>
> If building the documentation fails, run the tests locally before. 

## User flow in five steps

1. **Start and sign in:** Run `julia main.jl`. Choose **Sign up** to create an account, or **Log in** if you already have one.
2. **Choose an account role:** Sign up as `COMPANY`, `ADMIN`, or `VEHICLE_OPERATOR`. Vehicle operators must be assigned an already registered vehicle. After signup, log in with the new account.
3. **Open the role menu:** Companies and administrators can book shipments and review capacity. Administrators can also add vehicles and view all bookings. Vehicle operators can view bookings assigned to their vehicle.
4. **Book or share a shipment:** Enter pallets, destination, goods type, and pickup and delivery time windows. Review the route quote, then choose an available shared booking or book a new vehicle. Unused capacity may be offered to another company.
5. **Manage bookings:** Review your bookings, check available shared capacity, or cancel an eligible solo booking. Log out or exit when finished.

For the full project documentation, see the [documentation landing page](docs/src/index.md).

<!-- DO NOT EDIT ABOVE -->

## Contributing

<!-- DO NOT EDIT BELOW -->
See [CONTRIBUTING.md](CONTRIBUTING.md).
<!-- DO NOT EDIT ABOVE -->

## License

<!-- DO NOT EDIT BELOW -->
MIT. See [LICENSE](LICENSE).
<!-- DO NOT EDIT ABOVE -->
