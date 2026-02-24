from fastapi import APIRouter, Query
from typing import List
from app.services.get_reports import get_reports_in_bbox
from app.models.reports import ReportCreate, ReportResponse
from app.config import settings
from supabase import create_client

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
@router.post("/", response_model=List[ReportResponse]) # On s'attend à recevoir une liste ou un objet
async def create_report(report: ReportCreate):
    """
    Reçoit un signalement de Flutter et l'enregistre dans Supabase
    """
    # On transforme les données validées par Pydantic en dictionnaire
    report_data = report.model_dump(mode='json') 
    try:
        # On insère dans la table 'reports'
        response = supabase.table("reports").insert(report_data).execute()
        
        # On retourne les données (Supabase renvoie une liste par défaut)
        return response.data
    
    except Exception as e:
        print(f" Erreur lors de l'insertion Supabase : {e}")
        # On lève une erreur HTTP 500 propre pour FastAPI
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))
# ------------------------------ PUT / PATCH ? confirm a report (restart timestamp) -------
@router.put("/{id}/confirm")
def confirm_report():
    pass

# ------------------------------ DELETE notify that a report doesn't exist anymore --------
@router.delete("/{id}/delete")
def delete_report():
    pass