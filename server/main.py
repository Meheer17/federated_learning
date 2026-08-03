from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

try:
    from api.routes import devices, rounds, models
    from core.config import settings
    from models.database import engine, Base
except ImportError:
    from server.api.routes import devices, rounds, models
    from server.core.config import settings
    from server.models.database import engine, Base

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(devices.router, prefix=f"{settings.API_V1_STR}/devices", tags=["devices"])
app.include_router(rounds.router, prefix=f"{settings.API_V1_STR}/rounds", tags=["rounds"])
app.include_router(models.router, prefix=f"{settings.API_V1_STR}/models", tags=["models"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.PROJECT_NAME}
