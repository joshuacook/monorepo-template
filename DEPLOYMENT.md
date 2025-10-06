# Deployment

This document applies to the web client at `clients/web`.

- Only deployment path: push to GitHub. The GitHub repo is linked to Vercel and every push triggers a Vercel build/deploy.
- Production deploys: merges/pushes to the `main` branch become the Production deployment in Vercel.
- Preview deploys: pushes to feature branches and pull requests create Preview deployments.
- Configure environment variables in Vercel (Project Settings → Environment Variables). Do not rely on local `.env` for the web client runtime.
- No other deployment methods are supported for the web client (no Makefile, no manual Vercel CLI uploads, no Cloud Run).
- Rollback: use Vercel to promote a previous deployment or revert the Git commit.

Backend services are deployed via GCP using the Makefile; the web client is deployed exclusively via Vercel on Git pushes.
