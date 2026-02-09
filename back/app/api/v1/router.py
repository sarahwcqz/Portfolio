from fastapi import APIRouter
from app.api.v1.endpoints.itineraires import router as routes_router
from app.api.v1.endpoints.signalements import router as reports_router

api_router = APIRouter()

api_router.include_router(routes_router)
api_router.include_router(reports_router)
