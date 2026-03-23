from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
import models, schemas
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import JWTError, jwt
import os

router = APIRouter()
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
SECRET_KEY = os.getenv("SECRET_KEY", "college-bus-secret-key-trackmybus-123")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 1 week

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/register", response_model=schemas.UserOut)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)
    new_user = models.User(
        name=user.name, 
        email=user.email, 
        password=hashed_password, 
        role=user.role, 
        rfid_tag=user.rfid_tag,
        assigned_stop=user.assigned_stop
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login")
def login(req: schemas.LoginRequest, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == req.email).first()
    if not db_user or not verify_password(req.password, db_user.password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": db_user.email, "role": db_user.role, "id": db_user.id}, 
        expires_delta=access_token_expires
    )
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user": {
            "id": db_user.id,
            "name": db_user.name,
            "role": db_user.role,
            "email": db_user.email,
            "assigned_stop": db_user.assigned_stop
        }
    }

from fastapi.security import OAuth2PasswordBearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("id")
        role: str = payload.get("role")
        if user_id is None:
            raise credentials_exception
        return {"user_id": user_id, "role": role}
    except JWTError:
        raise credentials_exception

@router.post("/fcm-token")
def update_fcm_token(req: schemas.FCMTokenUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user = db.query(models.User).filter(models.User.id == current_user["user_id"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.fcm_token = req.fcm_token
    db.commit()
    return {"message": "FCM token updated successfully"}

# Parent-Student Linking
@router.post("/link-student", response_model=schemas.LinkingRequestResponse)
def create_link_request(req: schemas.StudentLinkRequest, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "parent":
        raise HTTPException(status_code=403, detail="Only parents can initiate linking")
    
    # Check if student exists
    student = db.query(models.User).filter(models.User.email == req.student_email, models.User.role == "student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Student with this email not found")
        
    # Check if already linked or pending
    existing = db.query(models.LinkingRequest).filter(
        models.LinkingRequest.parent_id == current_user["user_id"],
        models.LinkingRequest.student_email == req.student_email
    ).first()
    if existing:
        return existing
        
    new_request = models.LinkingRequest(
        parent_id=current_user["user_id"],
        student_email=req.student_email,
        status="pending"
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/linking-requests", response_model=list[schemas.LinkingRequestResponse])
def get_linking_requests(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    user = db.query(models.User).filter(models.User.id == current_user["user_id"]).first()
    if user.role == "student":
        return db.query(models.LinkingRequest).filter(models.LinkingRequest.student_email == user.email, models.LinkingRequest.status == "pending").all()
    elif user.role == "parent":
        return db.query(models.LinkingRequest).filter(models.LinkingRequest.parent_id == user.id).all()
    return []

@router.post("/approve-linking/{request_id}")
def approve_linking(request_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    req = db.query(models.LinkingRequest).filter(models.LinkingRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
        
    student = db.query(models.User).filter(models.User.id == current_user["user_id"]).first()
    if student.email != req.student_email:
        raise HTTPException(status_code=403, detail="You are not authorized to approve this request")
        
    req.status = "approved"
    student.parent_id = req.parent_id
    db.commit()
    return {"message": "Linking approved successfully"}

@router.get("/children", response_model=list[schemas.UserOut])
def get_children(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "parent":
        raise HTTPException(status_code=403, detail="Only parents can access this")
    return db.query(models.User).filter(models.User.parent_id == current_user["user_id"]).all()
