# Makefile for FastAPI CI/CD Showcase

.PHONY: help install test local setup-kube build

VENV = .venv
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip
UVICORN = $(VENV)/bin/uvicorn
PYTEST = $(VENV)/bin/pytest

help:
	@echo "Available commands:"
	@echo "  make install     - Create .venv and install dependencies"
	@echo "  make test        - Run python tests using .venv"
	@echo "  make local       - Run FastAPI app locally using .venv"
	@echo "  make setup-kube  - Sync cluster credentials (requires IP and BUCKET)"
	@echo "  make setup-kube  - Sync cluster credentials (requires IP and BUCKET)"
	@echo "  make build       - Build docker image locally"
	@echo "  make status      - Check if the App is running (Get Public IP)"

install:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

test:
	$(PYTEST) app/tests/

local:
	$(UVICORN) app.src.routes.main:app --reload --port 8000

setup-kube:
	@if [ -z "$(IP)" ] || [ -z "$(BUCKET)" ]; then \
		echo "Usage: make setup-kube IP=<PUBLIC_IP> BUCKET=<S3_BUCKET>"; \
		exit 1; \
	fi
	./setup-kube.sh $(IP) $(BUCKET)

build:
	docker build -t fastapi-app:local -f app/Dockerfile .

status:
	@echo "Checking AWS Project Status..."
	@aws ec2 describe-instances \
		--region us-east-1 \
		--filters "Name=tag:Name,Values=*-k3s-node" "Name=instance-state-name,Values=running" \
		--query "Reservations[*].Instances[*].PublicIpAddress" \
		--output text

