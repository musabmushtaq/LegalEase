# db/

This folder contains database schema, migrations, and documentation for LegalEase.

Suggested DB choices

- SQLite (for local prototyping)
- PostgreSQL (for production)

Schema & migrations

- Add SQL schema files or migration scripts (e.g., using Flyway, Alembic, or Knex migrations).

Local setup (Postgres example)

```bash
# start postgres (Docker)
docker run --name legalease-db -e POSTGRES_PASSWORD=changeme -p 5432:5432 -d postgres:15
# apply migrations (tool-specific)
```

Notes

- Document the schema and any migration steps in this README.
- Store database initialization scripts and sample data in this folder.
