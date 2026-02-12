from app.config import settings
from typing import List, Dict
from supabase import create_client
from datetime import datetime, timezone

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