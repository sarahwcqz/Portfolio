from pydantic import BaseModel
from datetime import datetime

class ReportResponse(BaseModel):
    id: str     # usefull to confirm or delete report
    type: str
    lat: float
    lng: float
    expires_at: datetime