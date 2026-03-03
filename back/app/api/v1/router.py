from fastapi import APIRouter
from app.api.v1.endpoints.routes import router as routes_router
from app.api.v1.endpoints.reports import router as reports_router

api_router = APIRouter()

api_router.include_router(routes_router)
api_router.include_router(reports_router)
