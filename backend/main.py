from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import json

app = FastAPI(title="Trackmybus API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from routes import auth, admin, driver, student, emergency
from websocket_manager import manager
from database import SessionLocal
from models import Bus, Route
from eta_engine import calculate_payload_eta
from services.geofence_service import check_geofence_triggers
import json

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])
app.include_router(driver.router, prefix="/api/driver", tags=["Driver"])
app.include_router(student.router, prefix="/api/student", tags=["Student"])
app.include_router(emergency.router, prefix="/api/emergency", tags=["Emergency"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Trackmybus API"}

@app.websocket("/ws/bus/{bus_id}")
async def websocket_endpoint(websocket: WebSocket, bus_id: str):
    await manager.connect_bus(websocket, bus_id)
    db = SessionLocal()
    
    # Extract ID from string like 'bus_102'
    bus_id_int = int(bus_id.split('_')[1]) if '_' in bus_id else None
    bus = db.query(Bus).filter(Bus.id == bus_id_int).first() if bus_id_int else None
    route_stops = None
    if bus and bus.route_id:
        route = db.query(Route).filter(Route.id == bus.route_id).first()
        if route:
            route_stops = route.stops
            
    if not route_stops:
        # Hardware fallback for demo testing if no route is assigned
        route_stops = [
            {"name": "College Main Gate", "lat": 10.0240, "lng": 76.3130},
            {"name": "Library", "lat": 10.0260, "lng": 76.3160},
            {"name": "Hostel Block A", "lat": 10.0290, "lng": 76.3190}
        ]
    else:
        # Convert JSON string to list if necessary
        if isinstance(route_stops, str):
            route_stops = json.loads(route_stops)
        
    try:
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            # Predict ETA using native speed and haversine
            spd = payload.get('speed', 0.0)
            lat = payload.get('lat', 0.0)
            lng = payload.get('lng', 0.0)
            
            # Trigger Geofence Check
            if bus_id_int:
                await check_geofence_triggers(db, bus_id_int, lat, lng, route_stops)
            
            eta_data = calculate_payload_eta(bus_id, lat, lng, spd, json.dumps(route_stops))
            
            if eta_data:
                payload['eta'] = eta_data
                data = json.dumps(payload)

            await manager.broadcast_bus(bus_id, data, exclude=websocket)
    except WebSocketDisconnect:
        manager.disconnect_bus(websocket, bus_id)
    finally:
        db.close()

@app.websocket("/ws/admin")
async def admin_websocket(websocket: WebSocket):
    await manager.connect_admin(websocket)
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_admin(websocket)
