from fastapi import HTTPException
from supabase import create_client
from app.config import settings

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


def check_user_exists(user_id: str) -> None:
    """Checks if user exists"""
    # TO DO: recup JWT 
    pass


def check_report_exists(report_id: str) -> dict:
    """
    Checks if report exists,
    returns data of report.
    """
    report = supabase.table("reports") \
        .select("id, type, infirmation_count") \
        .eq("id", report_id) \
        .single() \
        .execute()
    
    if not report.data:
        raise HTTPException(
            status_code=404,
            detail="Signalement introuvable"
        )
    
    return report.data


def check_user_has_not_voted(report_id: str, user_id: str) -> None:
    """Checks if user hasn't already voted for this report"""
    existing = supabase.table("report_confirmations") \
        .select("id") \
        .eq("report_id", report_id) \
        .eq("user_id", user_id) \
        .execute()
    
    if existing.data:
        raise HTTPException(
            status_code=400,
            detail="Vous avez déjà voté pour ce signalement"
        )