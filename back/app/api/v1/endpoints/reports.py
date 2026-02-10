from fastapi import APIRouter

router = APIRouter(prefix="/reports", tags=["reports"])

@router.post("/")
def create_report():
    return {"status": "success"}
    