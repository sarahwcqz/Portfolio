from fastapi import APIRouter, Body, HTTPException
from app.models.route import RouteRequest
from app.config import settings
import httpx

router = APIRouter(prefix="/routes", tags=["routes"])

@router.post("/")
async def calculate_route(payload: RouteRequest = Body(...)):
    try:
        route = await get_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
        )
        return route
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

ORS_URL = settings.ORS_URL
ORS_KEY = settings.ORS_KEY

async def get_route(start_lat, start_lng, dest_lat, dest_lng):
    headers = {
        "Authorization": ORS_KEY,
        "Content-Type": "application/json",
    }
    body = {
        "coordinates": [
            [start_lng, start_lat],
            [dest_lng, dest_lat],
        ],
        "instructions": True,
        "language": "fr",
    }

    #API call to ORS
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(ORS_URL, json=body, headers=headers)
        response.raise_for_status()
        # /!\ return distance : meters, duration : seconds
        return response.json()