.PHONY: help enable-services create-repo build deploy deploy-all print-config create-project link-billing bootstrap init-firestore

# Load .env if present and export variables
ifneq (,$(wildcard .env))
include .env
export
endif

# Configuration (override via environment or make VAR=value)
# No hardcoded defaults; values must come from .env or be passed explicitly
ACCOUNT ?=
PROJECT_ID ?=
PROJECT_NUMBER ?=
PROJECT_NAME ?=
REGION ?=
REPO ?=
MAIN_API_SERVICE ?=
TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)
BILLING_ACCOUNT ?=
BACKEND_URL ?=
IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO)/backend:$(TAG)

# Ensure TAG gets a default even if defined empty in .env
ifeq ($(strip $(TAG)),)
TAG := $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)
endif

# Firestore initialization inputs
FIRESTORE_MODE ?=
FIRESTORE_LOCATION ?=

# Backward compatibility: allow legacy SERVICE/API_SERVICE to populate MAIN_API_SERVICE
ifeq ($(strip $(MAIN_API_SERVICE)),)
ifneq ($(strip $(API_SERVICE)),)
MAIN_API_SERVICE := $(API_SERVICE)
endif
endif
ifeq ($(strip $(MAIN_API_SERVICE)),)
ifneq ($(strip $(SERVICE)),)
MAIN_API_SERVICE := $(SERVICE)
endif
endif

# Require helpers
define require_var
	@if [ -z "$($(1))" ]; then \
		echo "ERROR: $(1) is required. Set it in .env or pass '$(1)=value'." 1>&2; \
		exit 1; \
	fi
endef

_require-dotenv:
	@if [ ! -f .env ]; then \
		echo "ERROR: .env is required at repo root. Populate it from .env.example." 1>&2; \
		exit 1; \
	fi

_require-env-core: _require-dotenv
	$(call require_var,ACCOUNT)
	$(call require_var,PROJECT_ID)

_require-env-build: _require-env-core
	$(call require_var,REGION)
	$(call require_var,REPO)
	$(call require_var,TAG)

_require-env-deploy: _require-env-build
	$(call require_var,MAIN_API_SERVICE)

_require-env-billing: _require-env-core
	$(call require_var,BILLING_ACCOUNT)

_require-env-firestore: _require-env-core
	$(call require_var,FIRESTORE_MODE)
	$(call require_var,FIRESTORE_LOCATION)

help:
	@echo "Targets:"
	@echo "  make print-config          Show effective config values (loaded from .env)"
	@echo "  make create-project        Create GCP project ($(PROJECT_ID))"
	@echo "  make link-billing         Link project to BILLING_ACCOUNT"
	@echo "  make enable-services       Enable required GCP services (Run, AR, Cloud Build, Firestore, App Engine)"
	@echo "  make create-repo           Create Artifact Registry repo (idempotent)"
	@echo "  make build                 Build and push image via Cloud Build"
	@echo "  make deploy                Deploy to Cloud Run (uses .env for runtime vars)"
	@echo "  make deploy-all            Enable, create repo, build, and deploy"
	@echo "  make bootstrap             Create project, link billing, enable, repo"
	@echo "  make init-firestore        Initialize Firestore database (requires FIRESTORE_MODE and FIRESTORE_LOCATION)"
	@echo "\nUsage: make deploy-all PROJECT_ID=your-project REGION=us-central1 TAG=$(TAG)"

print-config:
	@echo PROJECT_ID=$(PROJECT_ID)
	@echo PROJECT_NUMBER=$(PROJECT_NUMBER)
	@echo PROJECT_NAME=$(PROJECT_NAME)
	@echo REGION=$(REGION)
	@echo REPO=$(REPO)
	@echo MAIN_API_SERVICE=$(MAIN_API_SERVICE)
	@echo TAG=$(TAG)
	@echo IMAGE=$(IMAGE)
	@echo ACCOUNT=$(ACCOUNT)
	@echo BILLING_ACCOUNT=$(BILLING_ACCOUNT)
	@echo BACKEND_URL=$(BACKEND_URL)
	@echo FIRESTORE_MODE=$(FIRESTORE_MODE)
	@echo FIRESTORE_LOCATION=$(FIRESTORE_LOCATION)

## Create a new GCP project (requires appropriate org/folder permissions)
create-project: _require-env-core
	$(call require_var,PROJECT_NAME)
	@# Idempotent create: skip if project exists
	@if gcloud projects describe $(PROJECT_ID) --account $(ACCOUNT) >/dev/null 2>&1; then \
		echo "Project $(PROJECT_ID) already exists; skipping creation."; \
	else \
		gcloud projects create $(PROJECT_ID) --name="$(PROJECT_NAME)" --account $(ACCOUNT); \
	fi

## Link billing: requires BILLING_ACCOUNT env var
link-billing: _require-env-billing
	@# Idempotent link: skip if already linked to this billing account
	@if [ "$(BILLING_ACCOUNT)" = "$$(gcloud beta billing projects describe $(PROJECT_ID) --account $(ACCOUNT) --format='value(billingAccountName)' | sed 's/billingAccounts\///')" ]; then \
		echo "Billing already linked to $(BILLING_ACCOUNT); skipping."; \
	else \
		gcloud beta billing projects link $(PROJECT_ID) --billing-account=$(BILLING_ACCOUNT) --account $(ACCOUNT); \
	fi


enable-services: _require-env-core
	gcloud services enable \
	  run.googleapis.com \
	  artifactregistry.googleapis.com \
	  cloudbuild.googleapis.com \
	  firestore.googleapis.com \
	  appengine.googleapis.com \
	  --project $(PROJECT_ID) --account $(ACCOUNT)

create-repo: _require-env-build
	- gcloud artifacts repositories create $(REPO) \
	  --repository-format=docker \
	  --location=$(REGION) \
	  --description="Interecho container images" \
	  --project $(PROJECT_ID) --account $(ACCOUNT)
	@echo "Repo ensure step completed (ignore 'ALREADY_EXISTS' errors)."

build: _require-env-build
	gcloud builds submit backend \
	  --tag $(IMAGE) \
	  --project $(PROJECT_ID) --account $(ACCOUNT)

deploy: _require-env-deploy
	@ENV_LIST=$$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | sed 's/\r$$//' | paste -sd, -); \
	if [ -z "$$ENV_LIST" ]; then \
	  echo "ERROR: No environment variables found in .env to pass to Cloud Run." 1>&2; exit 1; \
	fi; \
	gcloud run deploy $(MAIN_API_SERVICE) \
	  --image $(IMAGE) \
	  --region $(REGION) \
	  --allow-unauthenticated \
	  --set-env-vars $$ENV_LIST \
	  --project $(PROJECT_ID) --account $(ACCOUNT)

deploy-all: enable-services create-repo build deploy
	@echo "Deployment complete: $(MAIN_API_SERVICE) in $(REGION)."

# Bootstrap infra without deploying
bootstrap: create-project link-billing enable-services create-repo
	@echo "Bootstrap complete for $(PROJECT_ID) in $(REGION)."

## Initialize Firestore (Native or Datastore mode)
## FIRESTORE_MODE must be one of: native, datastore
## FIRESTORE_LOCATION should be a valid Firestore location (e.g., us-central, nam5)
init-firestore: _require-env-firestore
	@MODE_LOWER=$(shell echo "$(FIRESTORE_MODE)" | tr '[:upper:]' '[:lower:]'); \
	if [ "$$MODE_LOWER" = "native" ]; then \
	  DB_TYPE=firestore-native; \
	elif [ "$$MODE_LOWER" = "datastore" ]; then \
	  DB_TYPE=datastore-mode; \
	else \
	  echo "ERROR: FIRESTORE_MODE must be 'native' or 'datastore'" 1>&2; exit 1; \
	fi; \
	if gcloud firestore databases describe --project $(PROJECT_ID) --account $(ACCOUNT) >/dev/null 2>&1; then \
	  echo "Firestore database already exists; skipping creation."; \
	else \
	  gcloud firestore databases create \
	    --location=$(FIRESTORE_LOCATION) \
	    --type=$$DB_TYPE \
	    --project $(PROJECT_ID) --account $(ACCOUNT); \
	fi
