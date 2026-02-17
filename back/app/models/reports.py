from pydantic import BaseModel

class ReportResponse(BaseModel):
    id: str     # usefull to confirm or delete report
    type: str
    lat: float
    lng: float