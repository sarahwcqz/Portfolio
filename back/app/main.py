from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from app.api.v1.router import api_router


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # DEV
    allow_methods=["*"],
    allow_headers=["*"],
)

# routing
app.include_router(api_router, prefix="/api/v1")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True,log_level="debug") # DEV