from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: str
    rfid_tag: Optional[str] = None
    assigned_stop: Optional[str] = None

class BusCreate(BaseModel):
    name: str
    number_plate: str
    capacity: int
    driver_id: int
    route_id: Optional[int] = None

class RouteCreate(BaseModel):
    name: str
    stops: str # JSON string

class UserOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    rfid_tag: Optional[str] = None
    assigned_stop: Optional[str] = None
    parent_id: Optional[int] = None

    class Config:
        from_attributes = True

class FCMTokenUpdate(BaseModel):
    fcm_token: str

class StudentLinkRequest(BaseModel):
    student_email: str

class LinkingRequestResponse(BaseModel):
    id: int
    parent_id: int
    student_email: str
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    email: str
    password: str

class EmergencyAlertCreate(BaseModel):
    latitude: float
    longitude: float
    alert_type: str = "other"  # medical, safety, breakdown, other
    bus_id: Optional[int] = None

class EmergencyAlertResponse(BaseModel):
    id: int
    user_id: int
    user_role: str
    bus_id: Optional[int]
    timestamp: datetime
    latitude: float
    longitude: float
    alert_type: str
    status: str
    acknowledged_by: Optional[int]
    resolved_at: Optional[datetime]

    class Config:
        from_attributes = True

class FineCreate(BaseModel):
    student_id: int
    amount: float
    reason: str

class PaymentCreate(BaseModel):
    fine_id: Optional[int] = None
    amount: float

class AttendanceCreate(BaseModel):
    rfid_tag: Optional[str] = None
    bus_id: int

class AttendanceResponse(BaseModel):
    id: int
    user_id: int
    bus_id: int
    timestamp: datetime
    class Config:
        from_attributes = True

class MaintenanceCreate(BaseModel):
    bus_id: int
    issue_description: str

class MaintenanceResponse(BaseModel):
    id: int
    bus_id: int
    driver_id: int
    issue_description: str
    status: str
    reported_at: datetime
    class Config:
        from_attributes = True
