from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models, schemas
from .auth import get_current_user

router = APIRouter()

@router.get("/my-bus")
def get_my_bus(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can access this")
    
    bus = db.query(models.Bus).filter(models.Bus.driver_id == current_user["user_id"]).first()
    if not bus:
        # Fallback for demo if no bus is assigned yet
        return {"id": 102, "name": "Demo Bus 102 (Unassigned)", "number_plate": "DEMO-123"}
    
    return {
        "id": bus.id,
        "name": bus.name,
        "number_plate": bus.number_plate
    }

@router.post("/maintenance")
def report_issue(issue: schemas.MaintenanceCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    new_maint = models.Maintenance(
        bus_id=issue.bus_id, 
        driver_id=current_user["user_id"], 
        issue_description=issue.issue_description, 
        status="reported"
    )
    db.add(new_maint)
    db.commit()
    db.refresh(new_maint)
    return new_maint

@router.get("/maintenance")
def get_issues(db: Session = Depends(get_db)):
    return db.query(models.Maintenance).all()
