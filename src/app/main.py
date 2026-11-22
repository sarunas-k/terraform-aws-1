from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.imds import fetch_availability_zone
from app.routes import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.availability_zone = fetch_availability_zone()
    yield


app = FastAPI(lifespan=lifespan)
app.include_router(router)
