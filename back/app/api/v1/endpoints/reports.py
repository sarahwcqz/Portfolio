from typing import List
from app.services.get_reports import get_reports_in_bbox
from app.models.reports import ReportCreate, ReportResponse
from app.config import settings
from supabase import create_client
from fastapi import APIRouter, Query, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.utils.auth import get_current_user_id
from datetime import datetime, timezone, timedelta

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

router = APIRouter(prefix="/reports", tags=["reports"])

# --------------------------- GET reports from a bounding box -----------------------------
@router.get("/", response_model=List[ReportResponse])       # a list of ReportREsponses (from reports model)
async def get_reports(
    min_lat: float = Query(..., description="Latitude minimum"),
    max_lat: float = Query(..., description="Latitude maximum"),
    min_lng: float = Query(..., description="Longitude minimum"),
    max_lng: float = Query(..., description="Longitude maximum"),
):
    """
    Returns reports from a bounding box
    
    Example :
    GET /api/v1/reports?min_lat=48.8&max_lat=48.9&min_lng=2.3&max_lng=2.4
    """
    return await get_reports_in_bbox(min_lat, max_lat, min_lng, max_lng)


# ------------------------------ POST create a report ------------------------------------
INCIDENT_RADII = {
    "permanent": 10,
    "travaux": 5,
    "dégradation de la voie": 2,
    "obstruction de la voie": 4
}

INCIDENT_DURATIONS = {
    "permanent": timedelta(days=150),
    "travaux": timedelta(days=5),
    "dégradation": timedelta(days=90),
    "obstruction": timedelta(hours=2)
}
@router.post("/", response_model=List[ReportResponse]) # On s'attend à recevoir une liste ou un objet
async def create_report(
    report: ReportCreate, 
    user_id: str = Depends(get_current_user_id)
    ):
    """
    Reçoit un signalement de Flutter et l'enregistre dans Supabase
    """
    report_data = report.model_dump(mode='json') 
    report_data["user_id"] = user_id
    incident_type = report_data.get("type", "test").lower()
    report_data["radius_meters"] = INCIDENT_RADII.get(incident_type, 50)
    duration = INCIDENT_DURATIONS.get(incident_type, timedelta(minutes=15))
    expire_time = datetime.now(timezone.utc) + duration
    report_data["expires_at"] = expire_time.isoformat()
    try:
        response = supabase.table("reports").insert(report_data).execute()
        
        return response.data
    
    except Exception as e:
        print(f" Erreur lors de l'insertion Supabase : {e}")
        raise HTTPException(status_code=500, detail=str(e))
# ------------------------------ PUT / PATCH ? confirm a report (restart timestamp) -------
@router.put("/{id}/confirm")
def confirm_report():
    pass

# ------------------------------ DELETE notify that a report doesn't exist anymore --------
@router.delete("/{id}/delete")
def delete_report():
    pass

