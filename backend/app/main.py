import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Template Backend", version="0.1.0")

# CORS configuration
_origins_env = os.getenv("ALLOWED_ORIGINS", "*")
_origins = [o.strip() for o in _origins_env.split(",") if o.strip()]
_allow_all = len(_origins) == 1 and _origins[0] == "*"

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all else _origins,
    allow_credentials=not _allow_all,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/")
def root():
    return {"service": "backend", "status": "ok"}


# Versioned routes
@app.get("/v1")
def v1_root():
    return {"service": "backend", "version": 1, "status": "ok"}


@app.get("/v1/health")
def v1_health():
    return {"status": "ok"}
