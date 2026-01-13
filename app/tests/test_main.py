from fastapi.testclient import TestClient
from app.src.routes.main import app
import pytest

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "DevOps FastAPI" in response.json()["message"]

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_create_and_get_user():
    # Create user
    user_data = {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com"
    }
    response = client.post("/users/", json=user_data)
    assert response.status_code == 201
    
    # Get user
    response = client.get("/users/1")
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"