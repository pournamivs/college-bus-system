from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
import models, schemas

router = APIRouter()

@router.get("/users")
def get_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()

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
