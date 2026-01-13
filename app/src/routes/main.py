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

from fastapi.responses import HTMLResponse

@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DevOps K8s Platform</title>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;800&display=swap" rel="stylesheet">
        <style>
            :root {
                --primary: #6366f1;
                --surface: #111827;
                --surface-card: #1f2937;
                --text: #f3f4f6;
                --text-muted: #9ca3af;
            }
            body {
                font-family: 'Inter', sans-serif;
                background-color: var(--surface);
                color: var(--text);
                margin: 0;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                text-align: center;
            }
            .container {
                max-width: 800px;
                padding: 2rem;
            }
            h1 {
                font-size: 3rem;
                font-weight: 800;
                margin-bottom: 0.5rem;
                background: linear-gradient(to right, #818cf8, #c084fc);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }
            p.subtitle {
                font-size: 1.25rem;
                color: var(--text-muted);
                margin-bottom: 3rem;
            }
            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1.5rem;
                width: 100%;
            }
            .card {
                background-color: var(--surface-card);
                padding: 1.5rem;
                border-radius: 1rem;
                border: 1px solid rgba(255, 255, 255, 0.1);
                transition: transform 0.2s, border-color 0.2s;
                text-decoration: none;
                color: inherit;
                display: flex;
                flex-direction: column;
                align-items: center;
            }
            .card:hover {
                transform: translateY(-5px);
                border-color: var(--primary);
            }
            .icon {
                font-size: 2.5rem;
                margin-bottom: 1rem;
            }
            .card h3 {
                margin: 0;
                font-size: 1.1rem;
                margin-bottom: 0.5rem;
            }
            .card span {
                font-size: 0.9rem;
                color: var(--text-muted);
            }
            .badge {
                display: inline-block;
                padding: 0.25rem 0.75rem;
                background-color: rgba(99, 102, 241, 0.2);
                color: #818cf8;
                border-radius: 9999px;
                font-size: 0.8rem;
                margin-top: 2rem;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Zero-Touch DevOps</h1>
            <p class="subtitle">Fully Automated FastAPI + Kubernetes + GitOps Platform</p>
            
            <div class="grid">
                <a href="/docs" class="card">
                    <div class="icon">📖</div>
                    <h3>API Docs</h3>
                    <span>Swagger UI</span>
                </a>
                <a href="/grafana/" class="card" target="_blank">
                    <div class="icon">📊</div>
                    <h3>Grafana</h3>
                    <span>Dashboards</span>
                </a>
                <a href="/prometheus/" class="card" target="_blank">
                    <div class="icon">📈</div>
                    <h3>Prometheus</h3>
                    <span>Metrics</span>
                </a>
                <a href="https://github.com/thomasasamba-bot/fastapi-ci-cd-project" class="card" target="_blank">
                    <div class="icon">🐙</div>
                    <h3>GitHub</h3>
                    <span>Source Code</span>
                </a>
            </div>

            <div class="badge">Running on Kubernetes • v1.0.0</div>
        </div>
    </body>
    </html>
    """

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