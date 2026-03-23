from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base
import os
from dotenv import load_dotenv

load_dotenv()

try:
    import firebase_admin
    from firebase_admin import credentials
    cred = credentials.Certificate('firebase_credentials.json')
    firebase_admin.initialize_app(cred)
except ImportError:
    print("Firebase Admin SDK not installed. Notifications will be disabled.")
except Exception as e:
    print(f"Firebase Init Warning: {e}")

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./trackmybus.db")

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    Base.metadata.create_all(bind=engine)
