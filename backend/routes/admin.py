from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
import models, schemas

router = APIRouter()

@router.get("/users")
def get_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()

@router.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted"}

@router.put("/users/{user_id}")
def update_user(user_id: int, user_data: dict, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if "role" in user_data: user.role = user_data["role"]
    if "name" in user_data: user.name = user_data["name"]
    db.commit()
    return user

@router.post("/buses")
def create_bus(bus: schemas.BusCreate, db: Session = Depends(get_db)):
    new_bus = models.Bus(
        name=bus.name, 
        number_plate=bus.number_plate, 
        capacity=bus.capacity, 
        driver_id=bus.driver_id,
        route_id=bus.route_id
    )
    db.add(new_bus)
    db.commit()
    db.refresh(new_bus)
    return new_bus

@router.put("/buses/{bus_id}")
def update_bus(bus_id: int, bus_data: dict, db: Session = Depends(get_db)):
    bus = db.query(models.Bus).filter(models.Bus.id == bus_id).first()
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found")
    
    if "driver_id" in bus_data: bus.driver_id = bus_data["driver_id"]
    if "route_id" in bus_data: bus.route_id = bus_data["route_id"]
    if "name" in bus_data: bus.name = bus_data["name"]
    
    db.commit()
    return bus

@router.get("/buses")
def get_buses(db: Session = Depends(get_db)):
    return db.query(models.Bus).all()

@router.get("/drivers")
def get_drivers(db: Session = Depends(get_db)):
    return db.query(models.User).filter(models.User.role == "driver").all()

@router.post("/routes")
def create_route(route: schemas.RouteCreate, db: Session = Depends(get_db)):
    new_route = models.Route(name=route.name, stops=route.stops)
    db.add(new_route)
    db.commit()
    db.refresh(new_route)
    return new_route

@router.get("/routes")
def get_routes(db: Session = Depends(get_db)):
    return db.query(models.Route).all()

@router.post("/fines")
def create_fine(fine: schemas.FineCreate, db: Session = Depends(get_db)):
    new_fine = models.Fine(student_id=fine.student_id, amount=fine.amount, reason=fine.reason)
    db.add(new_fine)
    db.commit()
    db.refresh(new_fine)
    return new_fine

@router.get("/payments")
def get_admin_payments(db: Session = Depends(get_db)):
    return db.query(models.Payment).all()

@router.get("/maintenance", response_model=list[schemas.MaintenanceResponse])
def get_all_maintenance(db: Session = Depends(get_db)):
    return db.query(models.Maintenance).all()

@router.get("/emergency", response_model=list[schemas.EmergencyAlertResponse])
def get_all_emergency(db: Session = Depends(get_db)):
    return db.query(models.EmergencyAlert).all()

