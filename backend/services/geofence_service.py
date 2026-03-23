import math
from firebase_admin import messaging
from models import User, Bus
from sqlalchemy.orm import Session

GEOFENCE_RADIUS_METERS = 500
EXIT_BUFFER_METERS = 300 # To reset, bus must be 800m away

def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371000  # Radius of the Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2)**2 + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

async def check_geofence_triggers(db: Session, bus_id_int: int, lat: float, lng: float, route_stops: list):
    bus = db.query(Bus).filter(Bus.id == bus_id_int).first()
    if not bus:
        return

    # 1. Reset logic: If bus was at a stop and is now > 800m away, clear last_geofence_stop
    if bus.last_geofence_stop:
        # Find the coordinates of the last notified stop
        last_stop = next((s for s in route_stops if s['name'] == bus.last_geofence_stop), None)
        if last_stop:
            dist = haversine_distance(lat, lng, last_stop['lat'], last_stop['lng'])
            if dist > (GEOFENCE_RADIUS_METERS + EXIT_BUFFER_METERS):
                bus.last_geofence_stop = None
                db.commit()

    # 2. Trigger logic: Check all stops (or next few if we had sequence data)
    for stop in route_stops:
        stop_name = stop['name']
        
        # Skip if we already notified for this stop
        if bus.last_geofence_stop == stop_name:
            continue

        dist = haversine_distance(lat, lng, stop['lat'], stop['lng'])
        if dist <= GEOFENCE_RADIUS_METERS:
            # Trigger Notification
            await send_geofence_notification(db, bus_id_int, stop_name)
            
            # Record that we notified for this stop
            bus.last_geofence_stop = stop_name
            db.commit()
            break # Notify for one stop at a time

async def send_geofence_notification(db: Session, bus_id: int, stop_name: str):
    # Find all students/staff assigned to this stop
    target_users = db.query(User).filter(
        User.assigned_stop == stop_name,
        User.fcm_token.isnot(None)
    ).all()
    
    if not target_users:
        return

    try:
        # 1. Notify the users themselves
        tokens = [u.fcm_token for u in target_users]
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title="🚌 Bus Approaching!",
                body=f"The bus is within {GEOFENCE_RADIUS_METERS}m of {stop_name}. Please be ready!"
            ),
            data={"type": "GEOFENCE", "stop_name": stop_name, "bus_id": str(bus_id)},
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens
        )
        messaging.send_each_for_multicast(message)

        # 2. Notify their linked parents
        for user in target_users:
            if user.parent_id:
                parent = db.query(User).filter(User.id == user.parent_id).first()
                if parent and parent.fcm_token:
                    parent_message = messaging.Message(
                        notification=messaging.Notification(
                            title=f"🚌 {user.name}'s Bus Approaching",
                            body=f"The bus is approaching {stop_name} for {user.name}."
                        ),
                        data={
                            "type": "GEOFENCE",
                            "student_name": user.name,
                            "stop_name": stop_name,
                            "bus_id": str(bus_id)
                        },
                        android=messaging.AndroidConfig(priority="high"),
                        token=parent.fcm_token
                    )
                    messaging.send(parent_message)
        
        print(f"Geofence Alert: Notified {len(target_users)} users and their parents.")
    except Exception as e:
        print(f"Geofence FCM Error: {e}")
