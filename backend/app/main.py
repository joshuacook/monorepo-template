import os
import re
from fastapi import FastAPI, Depends, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Template Backend", version="0.1.0")

# CORS configuration
_origins_env = os.getenv("ALLOWED_ORIGINS", "https://*.vercel.app")
_origins_raw = [o.strip() for o in _origins_env.split(",") if o.strip()]
_allow_all = any(o == "*" for o in _origins_raw)

_exact_origins: list[str] = []
_wildcard_patterns: list[str] = []
for origin in _origins_raw:
    if origin == "*":
        continue
    if "*" in origin:
        _wildcard_patterns.append(origin)
    else:
        _exact_origins.append(origin)

def _pattern_to_regex(pat: str) -> str:
    # Example: https://*.vercel.app -> ^https://([a-z0-9-]+\.)*vercel\.app$
    # Escape dots, then replace '*.' with '([a-z0-9-]+\.)*'
    esc = re.escape(pat)
    esc = esc.replace(re.escape("*."), r"([a-z0-9-]+\.)*")
    return f"^{esc}$"

_regexes = [_pattern_to_regex(p) for p in _wildcard_patterns]
_combined_regex = "|".join(_regexes) if _regexes else None

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all else _exact_origins,
    allow_origin_regex=_combined_regex,
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
def v1_root(_=Depends(lambda: verify_api_token())):
    return {"service": "backend", "version": 1, "status": "ok"}


@app.get("/v1/health")
def v1_health(_=Depends(lambda: verify_api_token())):
    return {"status": "ok"}


def verify_api_token(authorization: str | None = Header(default=None)) -> None:
    """Require Authorization: Bearer <API_TOKEN> when API_TOKEN is set.

    If API_TOKEN is unset/empty, the check is bypassed (open).
    """
    configured = os.getenv("API_TOKEN", "").strip()
    if not configured:
        return
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = authorization.split(" ", 1)[1].strip()
    if token != configured:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
