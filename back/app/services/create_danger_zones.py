from typing import List, Tuple, Dict

# get reports fom DB
from app.config import settings
from supabase import create_client
from datetime import datetime, timezone

# polygons
from shapely.geometry import Point, Polygon


# ====================================================== Building functions =================================

#------------------------------------------ bounding box -----------------------------------------------
def calculate_bounding_box(
    start_lat: float,
    start_lng: float,
    dest_lat: float,
    dest_lng: float,
    margin: float = 0.05    # 1° lat = 111km => 5km = 0,05°
) -> Tuple[float, float, float, float]:
    """Calculates bounding box with margin of ~ 5km"""
    
    min_lat = min(start_lat, dest_lat) - margin
    max_lat = max(start_lat, dest_lat) + margin
    min_lng = min(start_lng, dest_lng) - margin
    max_lng = max(start_lng, dest_lng) + margin
    
    return min_lat, max_lat, min_lng, max_lng

# ------------------------------------------------- get reports from DB ------------------------------------


supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


async def get_reports_from_DB(
    min_lat: float,
    max_lat: float,
    min_lng: float,
    max_lng: float
) -> List[Dict]:
    """
    Récupère les signalements actifs dans une zone géographique.
    
    Returns:
        Liste de signalements avec {lat, lng, radius_meters}
    """

    now_iso = datetime.now(timezone.utc)

    try:
        response = supabase.table("reports") \
            .select("lat, lng, radius_meters") \
            .gte("lat", min_lat) \
            .lte("lat", max_lat) \
            .gte("lng", min_lng) \
            .lte("lng", max_lng) \
            .gt("expires_at", now_iso) \
            .execute()
        
        return response.data if response.data else []
    
    except Exception as e:
        print(f"Erreur lors de la récupération des signalements : {e}")
        return []

# ----------------------------------------------- create polygons -------------------------------------

def create_circle_polygon(
    lat: float,
    lng: float,
    radius_meters: float,
) -> Polygon:
    """Converts a point (report) into polygon to send it to ORS in avoid_polygones"""
    point = Point(lng, lat)

    #buffer uses degrees => conversion of meters in degrees
    radius_degrees = radius_meters / 111000
    circle = point.buffer(radius_degrees, quad_segs=2)

    return circle


# ==================================================== main function to assemble ===========================

async def create_danger_zones(
        start_lat: float,
        start_lng: float,
        dest_lat: float,
        dest_lng: float
) -> List[Polygon]:
    """
    calculate the geographical zone in which to get the reports from DB, transforms them into a list of polygons to inject in route 2 
    """

    min_lat, max_lat, min_lng, max_lng = calculate_bounding_box(start_lat, start_lng, dest_lat, dest_lng)

    reports = await get_reports_from_DB(min_lat, max_lat, min_lng, max_lng)

    report_polygons = []
    for report in reports:
        polygon = create_circle_polygon(
            lat=report['lat'],
            lng=report['lng'],
            radius_meters=report['radius_meters']
        )
        report_polygons.append(polygon)

    return report_polygons
