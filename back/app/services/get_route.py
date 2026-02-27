from app.config import settings
import httpx
# for type verification
from typing import Dict, List, Optional
# to decode polyline into -> geometry (to get the points of routes)
import polyline
from shapely.geometry import Polygon, MultiPolygon, mapping
from fastapi import HTTPException
import traceback

# ========================================== var ====================================

ORS_URL = settings.ORS_URL
ORS_KEY = settings.ORS_KEY



# ======================================== get_route ================================

async def get_route(
    start_lat: float,
    start_lng: float,
    dest_lat: float,
    dest_lng: float,
    preference: str,
    avoid_polygons: Optional[List[Polygon]] = None,
    with_instructions: bool = False
) -> Dict:
    """
    Fetches a route from OpenRouteService between two coordinates (start + dest)
    decode the polyline geometry, and return coordinates and summary (duration + distance).
    """


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
        "preference": preference,
        "instructions": with_instructions,
        "language": "fr",
    }

    # if we are in route 2, then add the list of polygons (multipolygonated) to the ORS body request
    if avoid_polygons:
        multi_polygons = MultiPolygon(avoid_polygons)
        body["options"] = {
            "avoid_polygons": mapping(multi_polygons)
        }

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(ORS_URL, json=body, headers=headers)
            
            if response.status_code != 200:
                print(f" ERREUR ORS DÉTECTÉE | Statut: {response.status_code}")
                print(f" Message ORS: {response.text}")
                response.raise_for_status()

            ORS_data = response.json()

        route_info = ORS_data['routes'][0]
        decoded_coord = polyline.decode(route_info['geometry'])
        coordinates = [{"lat": lat, "lng": long} for lat, long in decoded_coord]

        result = {
        "coordinates": coordinates,
        "duration": route_info['summary']['duration'],
        "distance": route_info['summary']['distance'],
    }

        if with_instructions:
            steps = route_info['segments'][0]['steps']
            result["instructions"] = [
                {
                    "step": idx + 1,
                    "instruction": step['instruction'],
                    "distance": step['distance'],
                    "duration": step['duration'],
                    "way_points": step['way_points'],
                }
                for idx, step in enumerate(steps)
            ]
        return result

    except httpx.HTTPStatusError as e:
        print(f" Erreur HTTP : {e.response.status_code} - {e.response.text}")
        raise HTTPException(status_code=e.response.status_code, detail="Erreur venant d'ORS")

    except Exception as e:
        print(" Erreur dans le back:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
