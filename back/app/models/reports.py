from pydantic import BaseModel
from datetime import datetime


class ReportCreate(BaseModel):
    user_id: str
    type: str
    lat: float
    lng: float
    expires_at: datetime
    
class ReportResponse(BaseModel):
    id: str     # usefull to confirm or delete report
    type: str
    lat: float
    lng: float
    expires_at: datetime