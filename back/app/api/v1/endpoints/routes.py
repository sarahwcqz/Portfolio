from fastapi import APIRouter, Body, HTTPException
from app.models.route import RouteRequest
from app.config import settings
import httpx
# for type verification
from typing import List, Dict
# to decode polyline into -> geometry (to get the points of routes)
import polyline


#===================================================== var ==================================================

router = APIRouter(prefix="/routes", tags=["routes"])


ORS_URL = settings.ORS_URL
ORS_KEY = settings.ORS_KEY


# ==================================================== functions ============================================

async def get_route(
    start_lat: float,
    start_lng: float,
    dest_lat: float,
    dest_lng: float,
    preference: str
) -> Dict:

    # def body + header
    headers = {
        "Authorization": ORS_KEY,
        "Content-Type": "application/json",
    }

    body = {
        "coordinates": [
            [start_lng, start_lat],
            [dest_lng, dest_lat],
        ],
        "preference" : preference,
        "instructions": False,
        "language": "fr",
    }

    #API call to ORS
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(ORS_URL, json=body, headers=headers)
        response.raise_for_status()         # a comprendre
        # /!\ return distance : meters, duration : seconds
        ORS_data = response.json()

    route_info = ORS_data['routes'][0]
    decoded_coord = polyline.decode(route_info['geometry'])
    coordinates = [{"lat": lat, "lng": long} for lat, long in decoded_coord]

    return {
        "coordinates": coordinates,
        "duration": route_info['summary']['duration'],
        "distance": route_info['summary']['distance'],
    }



# =================================================== routes execution =================================================

@router.post("/")
async def calculate_route(payload: RouteRequest = Body(...)):
    try:
        route1 = await get_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
            preference="shortest",      # a bien comprendre l'interet
        )

        # To be implemented -> route 2 w/ DB call for reports

        return {
            "success": True,
            "routes": [
                #route 1 : shortest
                {
                    "route_id": "shortest",
                    "name": "itinéraire le plus court",
                    "coordinates": route1["coordinates"],
                    "duration": route1["duration"],
                    "distance": route1["distance"],
                    "colors": "blue"
                }
            #route 2 : avoiding reports
            ]

        }


    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))