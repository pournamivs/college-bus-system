from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String)  # admin, driver, student
    rfid_tag = Column(String, unique=True, index=True, nullable=True) # simulated fingerprint
    fcm_token = Column(String, nullable=True)
    assigned_stop = Column(String, nullable=True)
    parent_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
class Bus(Base):
    __tablename__ = "buses"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    number_plate = Column(String, unique=True, index=True)
    capacity = Column(Integer)
    driver_id = Column(Integer, ForeignKey("users.id"))
    route_id = Column(Integer, ForeignKey("routes.id"), nullable=True)
    last_geofence_stop = Column(String, nullable=True)
    
class Route(Base):
    __tablename__ = "routes"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    stops = Column(String) # JSON string of stops
    
class Maintenance(Base):
    __tablename__ = "maintenance"
    id = Column(Integer, primary_key=True, index=True)
    bus_id = Column(Integer, ForeignKey("buses.id"))
    driver_id = Column(Integer, ForeignKey("users.id"))
    issue_description = Column(String)
    status = Column(String) # reported, in_progress, resolved
    reported_at = Column(DateTime, default=datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float)
    status = Column(String) # pending, completed
    payment_date = Column(DateTime, default=datetime.utcnow)

class Attendance(Base):
    __tablename__ = "attendance"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    bus_id = Column(Integer, ForeignKey("buses.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)


class EmergencyAlert(Base):
    __tablename__ = "emergency_alerts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    user_role = Column(String(50))
    bus_id = Column(String(50), nullable=True) # E.g., 'bus_1'
    timestamp = Column(DateTime, default=datetime.utcnow)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    alert_type = Column(String(100)) # SOS, Accident, Breakdown, Medical
    status = Column(String(50), default="active") # active, resolved
    acknowledged_by = Column(Integer, ForeignKey("users.id"), nullable=True) # admin_id
    resolved_at = Column(DateTime, nullable=True)

class LinkingRequest(Base):
    __tablename__ = "linking_requests"
    id = Column(Integer, primary_key=True, index=True)
    parent_id = Column(Integer, ForeignKey("users.id"))
    student_email = Column(String)
    status = Column(String, default="pending") # pending, approved, rejected
    created_at = Column(DateTime, default=datetime.utcnow)

class Fine(Base):
    __tablename__ = "fines"
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)
    reason = Column(String(200), nullable=False)
    status = Column(String(50), default="unpaid") # paid, unpaid, pending
