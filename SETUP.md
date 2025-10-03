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
- Copy `.env.example` to `.env` and fill all required values (infra + runtime). Do not pass variables to `make`; the Makefile requires `.env` and will fail if missing.
- Bootstrap core infra: `make bootstrap`.
- Initialize Firestore: set `FIRESTORE_MODE` and `FIRESTORE_LOCATION` in `.env`, then run `make init-firestore`.
- Build and deploy: `make deploy-all`.
