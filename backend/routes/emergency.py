from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import EmergencyAlert, User
from schemas import EmergencyAlertCreate, EmergencyAlertResponse
from routes.auth import get_current_user
from websocket_manager import manager
import firebase_admin
from firebase_admin import messaging
import models
import schemas

router = APIRouter()

@router.post("/trigger", response_model=schemas.EmergencyAlertResponse)
async def trigger_alert(alert: schemas.EmergencyAlertCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user_id = current_user.get("user_id")
    role = current_user.get("role")
    
    new_alert = models.EmergencyAlert(
        user_id=user_id,
        user_role=role,
        bus_id=alert.bus_id,
        latitude=alert.latitude,
        longitude=alert.longitude,
        alert_type=alert.alert_type,
        status="active"
    )
    
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    # Broadcast to admin websockets
    alert_payload = {
        "event": "SOS_ALERT",
        "data": {
            "id": new_alert.id,
            "user_id": new_alert.user_id,
            "user_role": new_alert.user_role,
            "bus_id": new_alert.bus_id,
            "latitude": new_alert.latitude,
            "longitude": new_alert.longitude,
            "alert_type": new_alert.alert_type,
            "status": new_alert.status,
            "timestamp": new_alert.timestamp.isoformat()
        }
    }
    await manager.broadcast_admin(alert_payload)
    
    # Push Notifications
    try:
        admin_users = db.query(User).filter(User.role == "admin", User.fcm_token.isnot(None)).all()
        tokens = [u.fcm_token for u in admin_users]
        if tokens:
            message = messaging.MulticastMessage(
                data={
                    "type": "SOS",
                    "alert_id": str(new_alert.id),
                    "role": role or "unknown"
                },
                notification=messaging.Notification(
                    title="🚨 EMERGENCY SOS ALERT",
                    body=f"SOS triggered by {role} ID: {user_id}"
                ),
                android=messaging.AndroidConfig(priority="high"),
                tokens=tokens,
            )
            response = messaging.send_each_for_multicast(message)
            if response.failure_count > 0:
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        if resp.exception and resp.exception.code in ['messaging/invalid-registration-token', 'messaging/registration-token-not-registered']:
                            invalid_user = db.query(User).filter(User.fcm_token == tokens[idx]).first()
                            if invalid_user:
                                invalid_user.fcm_token = None
                db.commit()

        # Notify Student's parent if applicable
        if role == "student":
            student_db = db.query(User).filter(User.id == user_id).first()
            if student_db and student_db.parent_id:
                parent = db.query(User).filter(User.id == student_db.parent_id).first()
                if parent and parent.fcm_token:
                    parent_msg = messaging.Message(
                        notification=messaging.Notification(
                            title=f"🚨 SOS Alert: {student_db.name}",
                            body=f"Your child {student_db.name} has triggered an SOS alert!"
                        ),
                        data={
                            "type": "SOS",
                            "student_name": student_db.name,
                            "alert_id": str(new_alert.id),
                            "bus_id": str(new_alert.bus_id) if new_alert.bus_id else ""
                        },
                        android=messaging.AndroidConfig(priority="high"),
                        token=parent.fcm_token
                    )
                    messaging.send(parent_msg)

    except Exception as e:
        print(f"FCM Multicast Error: {e}")
    
    return new_alert

@router.get("/", response_model=list[EmergencyAlertResponse])
async def get_alerts(db: Session = Depends(get_db)):
    return db.query(EmergencyAlert).order_by(EmergencyAlert.timestamp.desc()).all()
