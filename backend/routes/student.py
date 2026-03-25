from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models, schemas

router = APIRouter()

@router.get("/my-bus")
def get_student_bus(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user = db.query(models.User).filter(models.User.id == current_user["user_id"]).first()
    if not user or not user.assigned_stop:
        return {"id": 102, "name": "Demo Bus 102", "error": "No assigned stop found"}
    
    # Try to find route with this stop
    import json
    routes = db.query(models.Route).all()
    for r in routes:
        stops = json.loads(r.stops)
        if any(s['name'] == user.assigned_stop for s in stops):
            bus = db.query(models.Bus).filter(models.Bus.route_id == r.id).first()
            if bus:
                return {"id": bus.id, "name": bus.name}
    
    return {"id": 102, "name": "Demo Bus 102 (Stop not on active route)"}

@router.post("/attendance", response_model=schemas.AttendanceResponse)
def mark_attendance(attendance: schemas.AttendanceCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user = db.query(models.User).filter(models.User.id == current_user["user_id"]).first()
    
    new_att = models.Attendance(user_id=user.id, bus_id=attendance.bus_id)
    db.add(new_att)
    db.commit()
    db.refresh(new_att)
    return new_att

@router.get("/attendance")
def get_attendance(db: Session = Depends(get_db)):
    return db.query(models.Attendance).all()

from routes.auth import get_current_user

@router.get("/fines")
def get_fines(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(models.Fine).filter(models.Fine.student_id == current_user["user_id"]).all()

@router.post("/pay")
def pay_fine(payment: schemas.PaymentCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    # Create payment record
    new_payment = models.Payment(
        student_id=current_user["user_id"], 
        amount=payment.amount, 
        status="completed"
    )
    db.add(new_payment)
    
    # If it's paying for a specific fine, update the fine status
    if payment.fine_id:
        fine = db.query(models.Fine).filter(models.Fine.id == payment.fine_id).first()
        if fine:
            fine.status = "paid"
            
    db.commit()
    db.refresh(new_payment)
    return new_payment
