# Web Client

Next.js app (App Router, TypeScript) located at `clients/web`.

- Scripts: `npm run dev`, `npm run build`, `npm run start`
- Uses `NEXT_PUBLIC_API_BASE_URL` to point at the backend (Cloud Run).
- Deploy on Vercel or your preferred platform.

Note: This monorepo deploys backend config from the repo root `.env`; the web client does not require a separate local `.env` for this template.

