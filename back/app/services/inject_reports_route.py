from shapely.geometry import Point
from typing import List, Tuple

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



def create_circle_polygon(
    lat: float,
    lng: float,
    radius_meters: float,
) -> List[List[float]]:
    """Converts a point (report) into polygon to send it to ORS in avoid_polygones"""
    point = Point(lng, lat)

    #buffer uses degrees => conversion of meters in degrees
    radius_degrees = radius_meters / 111000
    circle = point.buffer(radius_degrees, quad_segs=2)
    coords = list(circle.exterior.coords)

    return coords
