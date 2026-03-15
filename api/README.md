# api/

This folder contains the backend API for LegalEase. It is responsible for proxying AI calls, managing authentication, and storing/retrieving data from the database.

Suggested stack (example)

- Node.js + Express or Python + FastAPI
- Docker for containerized deployment
- Postgres or other relational DB (see `../db/`)

Local development (Node example)

```bash
cd api
# create .env with API keys and DB connection (see docs/deployment.md)
npm install
npm run dev
```

Docker (example)

```bash
# build
docker build -t legalease-api .
# run (example using env file)
docker run --env-file .env -p 8080:8080 legalease-api
```

Deployment

- Prefer deploying via a container platform (e.g., AWS ECS, Google Cloud Run, Azure Container Instances) or a PaaS that supports Docker.
- Keep secret management in your chosen platform's secret store (do not commit `.env` to version control).

Notes

- Add `api/README.md` details specific to the chosen language/framework and endpoints once implemented.
- The API should be the place where API keys for third-party AI providers (Gemini) are stored and used; the mobile and web apps should call the API rather than direct external APIs.
