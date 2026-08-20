# SwiftPrintAPI

A REST API for managing a 3D print queue, printer fleet, and filament inventory - built with **Swift 6** and **Vapor 4**. Users register, log in, and manage their own printers, filament spools, and print jobs, with print jobs automatically depleting filament weight and accumulating printer usage on creation, patch, and delete.

Built as a backend portfolio project, loosely inspired by BambuLab-style 3D printer management (without live printer/MQTT integration by design - this project focuses on the API/data layer).

## Features

- **JWT authentication** - register and log in with a hashed password (BCrypt), receive a signed JWT, and use it as a Bearer token on every protected route.
- **Ownership-scoped resources** - every printer, filament, and print job belongs to the authenticated user; users can never read, edit, or delete another user's data.
- **Full CRUD** on printers, filaments, and print jobs, plus user registration, login, and profile updates.
- **Real business logic**, not just a CRUD wrapper:
  - Creating a print job deducts its weight from the linked filament and adds its duration to the linked printer's total print time.
  - Patching a print job recalculates those deltas against the filament and printer instead of just overwriting fields.
  - Deleting a print job reverses its effect, restoring the filament weight and printer minutes it had consumed.
  - Print cost is computed server-side from `weightGrams` and the filament's `costPerKg` - never trusted from the client.
- **Automated test suite** using Swift's modern Testing framework (XCTest's successor) and `VaporTesting`, covering registration/login, ownership enforcement across all three resources, print job business logic, and auth failure cases.
- **Dockerized** - Postgres, the app, and one-off migration/revert services all run via `docker compose`.

## Tech Stack

| Layer          | Technology                          |
|----------------|--------------------------------------|
| Language       | Swift 6                              |
| Framework      | [Vapor 4](https://vapor.codes)       |
| ORM            | Fluent                               |
| Database       | PostgreSQL                           |
| Auth           | JWTKit + BCrypt                      |
| Testing        | Swift Testing + VaporTesting         |
| Containerization | Docker / Docker Compose            |
| CI             | GitHub Actions                       |

## Architecture

Each resource follows a consistent three-layer pattern:

- **Model** (`Sources/SwiftPrintAPI/Models`) - the Fluent-backed database representation.
- **Migration** (`Sources/SwiftPrintAPI/Migrations`) - defines the table schema.
- **DTOs** (`Sources/SwiftPrintAPI/DTOs`) - separate `Create`, response, and `Patch` shapes per resource, so clients never see or set fields like `passwordHash`, ownership IDs, or server-computed totals.
- **Controller** (`Sources/SwiftPrintAPI/Controllers`) - a `RouteCollection` handling decode → authorize → business logic → save → respond.

### Data model

- **User** - `name`, `email`, `passwordHash`, has many printers and filaments.
- **Printer** - `title`, `area`, `totalPrintMinutes` (accumulated automatically), belongs to a user.
- **Filament** - `title`, `color`, `material`, `weightGrams` (depleted automatically), `costPerKg`, belongs to a user.
- **PrintJob** - `duration`, `weightGrams`, `success`, `cost` (computed), references a user, printer, and filament.

## API Overview

All routes below except registration and login require an `Authorization: Bearer <token>` header.

| Method | Route                  | Description                          |
|--------|-------------------------|---------------------------------------|
| POST   | `/users/register`       | Create a new user                     |
| POST   | `/users/login`          | Log in, receive a JWT                 |
| PATCH  | `/users`                | Update the current user               |
| POST   | `/printers/register`    | Create a printer                      |
| GET    | `/printers`             | List the current user's printers      |
| GET    | `/printers/:id`         | Get one printer                       |
| PATCH  | `/printers/:id`         | Update a printer                      |
| DELETE | `/printers/:id`         | Delete a printer                      |
| POST   | `/filaments/register`   | Create a filament spool               |
| GET    | `/filaments`            | List the current user's filaments     |
| GET    | `/filaments/:id`        | Get one filament                      |
| PATCH  | `/filaments/:id`        | Update a filament                     |
| DELETE | `/filaments/:id`        | Delete a filament                     |
| POST   | `/printJobs/register`   | Log a print job                       |
| GET    | `/printJobs`            | List the current user's print jobs    |
| GET    | `/printJobs/:id`        | Get one print job                     |
| PATCH  | `/printJobs/:id`        | Update a print job                    |
| DELETE | `/printJobs/:id`        | Delete a print job                    |

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Swift 6 toolchain (for local development outside Docker)

### Run with Docker

```bash
# Build the app image
docker compose build

# Start the database
docker compose up db -d

# Run migrations
docker compose run migrate

# Start the app
docker compose up app
```

The API will be available at `http://localhost:8080`.

### Run locally with Swift Package Manager

```bash
swift build
swift run
```

### Environment variables

| Variable      | Description                              | Default (Docker)     |
|----------------|-------------------------------------------|------------------------|
| `DATABASE_HOST` | Postgres host                            | `db`                   |
| `DATABASE_NAME` | Postgres database name                   | `vapor_database`       |
| `DATABASE_USERNAME` | Postgres username                    | `vapor_username`       |
| `DATABASE_PASSWORD` | Postgres password                    | `vapor_password`       |
| `JWT_SECRET`    | Signing key for JWTs                     | falls back to a dev-only insecure default |

### Running Tests

```bash
swift test
```

The test suite spins up a fresh, isolated instance of the app and database schema for every test, so each one runs independently with no shared state.

## Project Structure

```
Sources/SwiftPrintAPI/
├── Auth/            # JWT payload definition
├── Controllers/      # Route handlers (one per resource)
├── DTOs/              # Create / Response / Patch shapes, per resource
├── Migrations/        # Fluent schema migrations
├── Models/             # Fluent database models
├── configure.swift     # App configuration, DB + JWT setup
└── routes.swift         # Route registration

Tests/SwiftPrintAPITests/
└── SwiftPrintAPITests.swift   # Integration tests
```
