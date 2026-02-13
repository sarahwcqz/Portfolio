from app.config import settings
import httpx
# for type verification
from typing import Dict, List, Optional
# to decode polyline into -> geometry (to get the points of routes)
import polyline
from shapely.geometry import Polygon, MultiPolygon, mapping


# ========================================== var ====================================

ORS_URL = settings.ORS_URL
ORS_KEY = settings.ORS_KEY



# ======================================== get_route ================================

async def get_route(
    start_lat: float,
    start_lng: float,
    dest_lat: float,
    dest_lng: float,
    avoid_polygons: Optional[List[Polygon]] = None
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
        "preference" : "recommended",
        "instructions": False,
        "language": "fr",
    }

    # if we are in route 2, then add the list of polygons (multipolygonated) to the ORS body request
    if avoid_polygons:
        multi_polygons = MultiPolygon(avoid_polygons)
        body["options"] = {
            "avoid_polygons": mapping(multi_polygons)
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