import os
from pathlib import Path

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

BASE_DIR = Path(__file__).resolve().parent

router = APIRouter()
templates = Jinja2Templates(directory=BASE_DIR / "templates")

# Set by EC2 user data. Empty hides the shut-down button
INFRA_CONTROL_URL = os.environ.get("INFRA_CONTROL_URL", "").rstrip("/")


@router.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "availability_zone": request.app.state.availability_zone,
            "infra_control_url": INFRA_CONTROL_URL,
        },
    )


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
