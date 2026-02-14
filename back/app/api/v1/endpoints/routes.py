from fastapi import APIRouter, Body, HTTPException
from app.models.route import RouteRequest
from app.services.get_route import get_route
from app.services.create_danger_zones import create_danger_zones


#===================================================== var ==================================================

router = APIRouter(prefix="/routes", tags=["routes"])



# =================================================== routes execution =================================================

@router.post("/")
async def calculate_route(payload: RouteRequest = Body(...)):
    """
    Calculates 2 itineraries :
        - route1 : shortest
        - route2 : safest (avoids reports)
    """
    try:
        danger_zones = await create_danger_zones(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
        )

        route1 = await get_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
            preference="shortest",
            avoid_polygons=None
        )

        route2 = await get_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
            preference="recommended",
            avoid_polygons=danger_zones
        )

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
                    "color": "blue"
                },
                #route 2 : avoiding reports
                {
                    "route_id": "avoid",
                    "name": "itinéraire le plus sur",
                    "description": f"Évite {len(danger_zones)} zone(s) signalée(s)",
                    "coordinates": route2["coordinates"],
                    "duration": route2["duration"],
                    "distance": route2["distance"],
                    "color": "green"
                }
            ]

        }


    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
# ===================================================== ENDPOINT INSTRUCTIONS =================================================


@router.post("/{route_id}/instructions")
async def get_route_instructions(
    route_id: str,
    payload: RouteRequest = Body(...)
):
    """
    Récupère les instructions détaillées pour la route sélectionnée
    """
    try:
        # Détermine la préférence selon le route_id
        preference = "shortest" if route_id == "shortest" else "recommended"
        
        # Récupère les zones dangereuses (seulement pour route avoid)
        danger_zones = []
        if route_id == "avoid":
            danger_zones = await create_danger_zones(
                start_lat=payload.start_lat,
                start_lng=payload.start_lng,
                dest_lat=payload.dest_lat,
                dest_lng=payload.dest_lng,
            )
        
        # Appel avec instructions=True
        route = await get_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.dest_lat,
            dest_lng=payload.dest_lng,
            preference=preference,
            avoid_polygons=danger_zones if route_id == "avoid" else None,
            with_instructions=True  # ✅ IMPORTANT
        )
        
        return {
            "route_id": route_id,
            "instructions": route["instructions"]
        }
        
    except Exception as e:
        print(f"❌ Erreur dans get_route_instructions: {e}")
        raise HTTPException(status_code=500, detail=str(e))