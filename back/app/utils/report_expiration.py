from datetime import datetime, timedelta, timezone

EXPIRATION_DURATIONS = {
    "permanent": timedelta(days=150),
    "travaux": timedelta(days=5),
    "dégradation": timedelta(days=90),
    "obstruction": timedelta(hours=2),
}

DEFAULT_DURATION = timedelta(hours=3)

def get_expiration_date(report_type: str) -> datetime:
    """Calculates expiration date for reports' types"""
    duration = EXPIRATION_DURATIONS.get(report_type, DEFAULT_DURATION)
    return datetime.now(timezone.utc) + duration