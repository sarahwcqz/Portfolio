from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class ReportCreate(BaseModel):
    type: str
    lat: float
    lng: float
    expires_at: Optional[datetime] = None
    
class ReportResponse(BaseModel):
    id: str     # usefull to confirm or delete report
    type: str
    lat: float
    lng: float
    expires_at: datetime
    radius_meters: int = 50

    model_config = ConfigDict(from_attributes=True)