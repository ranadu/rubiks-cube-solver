from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from solver import solve  # ← this uses your solver.py

app = FastAPI()

# CORS for frontend testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class CubeRequest(BaseModel):
    cube: str

@app.post("/solve")
def solve_cube(data: CubeRequest):
    try:
        moves = solve(data.cube)
        return {"solution": moves}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))