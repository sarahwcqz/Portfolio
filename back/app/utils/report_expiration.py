from datetime import datetime, timedelta, timezone

EXPIRATION_DURATIONS = {
    "accident": timedelta(hours=2),
    "travaux": timedelta(days=7),
    "danger": timedelta(hours=24),
    "test": timedelta(hours=1),
}

DEFAULT_DURATION = timedelta(hours=3)

def get_expiration_date(report_type: str) -> datetime:
    """Calculates expiration date for reports' types"""
    duration = EXPIRATION_DURATIONS.get(report_type, DEFAULT_DURATION)
    return datetime.now(timezone.utc) + duration