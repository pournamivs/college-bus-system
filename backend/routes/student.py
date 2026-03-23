from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter()

@router.post("/attendance")
def mark_attendance(attendance: dict, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.rfid_tag == attendance["rfid_tag"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found for RFID tag")
    
    new_att = models.Attendance(user_id=user.id, bus_id=attendance["bus_id"])
    db.add(new_att)
    db.commit()
    db.refresh(new_att)
    return new_att

@router.get("/attendance")
def get_attendance(db: Session = Depends(get_db)):
    return db.query(models.Attendance).all()

@router.post("/payments")
def create_payment(payment: dict, db: Session = Depends(get_db)):
    new_payment = models.Payment(student_id=payment["student_id"], amount=payment["amount"], status="completed")
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment

@router.get("/payments")
def get_payments(db: Session = Depends(get_db)):
    return db.query(models.Payment).all()
