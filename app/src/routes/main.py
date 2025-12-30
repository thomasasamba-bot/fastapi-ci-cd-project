from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel
from typing import Optional
import os
import logging
import prometheus_client
from prometheus_client import Counter

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="DevOps FastAPI Demo",
    description="A production-ready API for DevOps showcase",
    version=os.getenv("APP_VERSION", "1.0.0")
)

class HealthResponse(BaseModel):
    status: str
    version: str
    environment: str

class User(BaseModel):
    id: int
    username: str
    email: str
    active: bool = True

# In-memory "database"
users_db = {}

REQUEST_COUNT = Counter("app_requests_total", "Total HTTP requests")

@app.middleware("http")
async def metrics_middleware(request, call_next):
    REQUEST_COUNT.inc()
    return await call_next(request)

@app.get("/")
async def root():
    return {"message": "DevOps FastAPI CI/CD is running"}

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        version=app.version,
        environment=os.getenv("ENVIRONMENT", "development")
    )

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    return users_db[user_id]

@app.post("/users/", status_code=201)
async def create_user(user: User):
    if user.id in users_db:
        raise HTTPException(status_code=400, detail="User already exists")
    users_db[user.id] = user
    logger.info(f"Created user: {user.username}")
    return {"message": "User created successfully"}

@app.get("/users/")
async def list_users(active: Optional[bool] = None):
    if active is None:
        return list(users_db.values())
    return [user for user in users_db.values() if user.active == active]

@app.get("/metrics")
def metrics():
    return Response(prometheus_client.generate_latest(), media_type="text/plain")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) # nosec