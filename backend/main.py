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
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    # If moves are already a list of dicts with 'move' and 'hint', return directly
    if isinstance(moves[0], dict) and "move" in moves[0]:
        return {"solution": moves}

    # Otherwise, assume moves is a list of strings and add hints
    hints = {
        "U": "Rotate the top layer to align cross pieces.",
        "R": "Position right face edge correctly.",
        "U'": "Undo top rotation to maintain orientation.",
        "L": "Work on left side pairing.",
        "F2": "Double turn to flip front edges.",
        "D'": "Adjust bottom face for next step.",
        "R2": "Place right corner efficiently.",
    }

    response = [
        {"move": move, "hint": hints.get(move, "Execute move carefully.")}
        for move in moves
    ]

    return {"solution": response}