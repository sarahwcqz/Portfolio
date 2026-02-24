from fastapi import APIRouter, Query
from typing import List
from app.models.reports import ReportResponse
from app.services.get_reports import get_reports_in_bbox
# to restart timestamp
from datetime import datetime, timezone
from app.config import settings
from supabase import create_client
from app.utils.report_expiration import get_expiration_date
from app.utils.report_validations import (
    check_user_exists,
    check_report_exists,
    check_user_has_not_voted
)

router = APIRouter(prefix="/reports", tags=["reports"])
supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

# Minimum of votes for a report to expire
INFIRM_THRESHOLD = 3

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
@router.post("/")
def create_report():
    return {"status": "success"}

# ------------------------------ PATCH confirm a report ----------------------------------
@router.patch("/{report_id}/confirm")
def confirm_report(
    report_id: str,
    user_id: str = "temp-user-id"  # TO DO: Récup JWT
):
    """
    Confirms that a report is still present
    => reset expires_at w/ get_expiration_date()
    """

    #report validations
    check_user_exists(user_id)
    report = check_report_exists(report_id)
    check_user_has_not_voted(report_id, user_id)

    # create row in report_confirmations table
    supabase.table("report_confirmations").insert({
        "report_id": report_id,
        "user_id": user_id,         # unicity? or automatique?
    }).execute()

    # reset expires_at depending on the type of report
    new_expires_at = get_expiration_date(report["type"])

    supabase.table("reports").update({
        "expires_at": new_expires_at.isoformat(),
    }).eq("id", report_id).execute()

    return {
        "status": "confirmed",
        "message": "Merci pour votre confirmation",
        "new_expires_at": new_expires_at.isoformat()    # DEBUG to be removed
    }

# ------------------------------ PATCH infirm a report --------------------------------------------
@router.patch("/{report_id}/infirm")
def infirm_report(
    report_id: str,
    user_id: str = "temp-user-id"
):
    """
    The report is no longer present
    =>
        - if < 3 votes : increment counter
        - if >= 3 votes : expires_at = now
    """

    #report validations
    check_user_exists(user_id)
    report = check_report_exists(report_id)
    check_user_has_not_voted(report_id, user_id)

    # create row in report_confirmations table
    supabase.table("report_confirmations").insert({
        "report_id": report_id,
        "user_id": user_id,         # unicity? or automatique?
    }).execute()

    # Increment counter
    new_confirm_count = report.get("confirmation_count", 0) + 1

    # IF >= 3 votes -> Expires now
    if new_confirm_count >= INFIRM_THRESHOLD:
        supabase.table("reports").update({
            "expires_at": datetime.now(timezone.utc).isoformat()
        }).eq("id", report_id).execute()
        
        return {
            "status": "resolved",
            "message": "Merci pour votre vote! =)",
            "confirm_count": new_confirm_count    # DEBUG to be removed
        }
    
    # IF < 3 votes -> increment counter
    else:
        supabase.table("reports").update({
            "confirm_count": new_confirm_count
        }).eq("id", report_id).execute()
        
        return {
            "status": "vote_recorded",
            "message": "Vote bien pris en compte, merci!",
            "confirm_count": new_confirm_count
        }