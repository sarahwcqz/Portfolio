from typing import List, Dict
from datetime import datetime, timezone
from supabase import create_client
from app.config import settings

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

async def get_reports_in_bbox(
    min_lat: float,
    max_lat: float,
    min_lng: float,
    max_lng: float,
) -> List[Dict]:
    """
    Gets reports active from bounding box.
    Returns id, type, lat, lng.
    """
    now_iso = datetime.now(timezone.utc)

    try:
        response = supabase.table("reports") \
            .select("id, type, lat, lng") \
            .gte("lat", min_lat) \
            .lte("lat", max_lat) \
            .gte("lng", min_lng) \
            .lte("lng", max_lng) \
            .gt("expires_at", now_iso) \
            .execute()

        return response.data if response.data else []

    except Exception as e:
        print(f"Erreur récupération signalements : {e}")
        return []