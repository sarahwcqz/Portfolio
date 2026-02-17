# app/api/v1/endpoints/reports.py
from fastapi import APIRouter, Query
from typing import List
from app.models.reports import ReportResponse
from app.services.get_reports import get_reports_in_bbox

router = APIRouter(prefix="/reports", tags=["reports"])

# --------------------------- GET reports from a bounding box -----------------------------
@router.get("/", response_model=List[ReportResponse])
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
@router.post("/")
def create_report():
    return {"status": "success"}

# ------------------------------ PUT / PATCH ? confirm a report (restart timestamp) -------
@router.put("{id}/confirm")
def confirm_report():
    pass

# ------------------------------ DELETE notify that a report doesn't exist anymore --------
@router.delete("/{id}/delete")
def delete_report():
    pass