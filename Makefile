# Makefile for FastAPI CI/CD Showcase

.PHONY: help test local setup-kube build

help:
	@echo "Available commands:"
	@echo "  make install     - Install python dependencies"
	@echo "  make test        - Run python tests"
	@echo "  make local       - Run FastAPI app locally"
	@echo "  make setup-kube  - Sync cluster credentials (requires IP and BUCKET)"
	@echo "  make build       - Build docker image locally"

install:
	pip install -r requirements.txt

test:
	pytest app/tests/

local:
	uvicorn app.src.routes.main:app --reload --port 8000

setup-kube:
	@if [ -z "$(IP)" ] || [ -z "$(BUCKET)" ]; then \
		echo "Usage: make setup-kube IP=<PUBLIC_IP> BUCKET=<S3_BUCKET>"; \
		exit 1; \
	fi
	./setup-kube.sh $(IP) $(BUCKET)

build:
	docker build -t fastapi-app:local -f app/Dockerfile .
