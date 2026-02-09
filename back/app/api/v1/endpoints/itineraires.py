from fastapi import APIRouter

router = APIRouter(prefix="/routes", tags=["routes"])

@router.post("/")
def calculate_route():
    return {"status": "success"}