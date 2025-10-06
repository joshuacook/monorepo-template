# Setup

External steps to get started:

0. Create a new project using this repo as a template.
1. Set up Clerk organization and application → get publishable + secret keys. These go in `.env`.
2. Create Vercel project → link to GitHub repo, configure env vars.
3. Create GCP project (or reuse) → enable Cloud Run, Cloud Build, Firestore, Artifact Registry. (use Makefile)

GCP auth prerequisites:
- Install the Google Cloud SDK (`gcloud`).
- Authenticate and set defaults: `gcloud auth login && gcloud auth application-default login`.
- Select the account and project: `gcloud config set account <ACCOUNT>` and `gcloud config set project <PROJECT_ID>`.

Makefile quickstart (backend builds from `backend/`):
- Copy `.env.example` to `.env` and fill all required values (infra + runtime).
  - Required infra: `ACCOUNT`, `PROJECT_ID`, `PROJECT_NAME`, `REGION`, `REPO`, `MAIN_API_SERVICE`, `BILLING_ACCOUNT`.
  - Firestore: `FIRESTORE_MODE=native`, `FIRESTORE_LOCATION=<region>` (irreversible per project).
  - Backend CORS: `ALLOWED_ORIGINS=https://*.vercel.app` (add prod domain as needed).
- Do not pass variables to `make`; the Makefile uses `.env` and fails if missing.
- Bootstrap core infra: `make bootstrap`.
- Initialize Firestore: `make init-firestore`.
- Build and deploy backend: `make deploy-all`.

Backend
- Stack: FastAPI + Uvicorn (deployed on Cloud Run).
- Image registry: Artifact Registry (Docker) in your configured `REGION` and `REPO`.
- Routes:
  - `GET /healthz` and `GET /` (basic OK responses)
  - `GET /v1` and `GET /v1/health` (versioned endpoints)
- CORS: `ALLOWED_ORIGINS` supports wildcards such as `https://*.vercel.app`.

Web Client (Vercel)
- The web app at `clients/web` deploys only via GitHub → Vercel.
- Configure the Vercel project with Root Directory `clients/web` and set env vars:
  - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
  - `NEXT_PUBLIC_API_BASE_URL` = Cloud Run service URL
- Push to `main` for production; branches/PRs create preview deployments.
