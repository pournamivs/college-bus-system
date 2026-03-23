from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def seed():
    db = SessionLocal()
    try:
        # Create Tables
        models.Base.metadata.create_all(bind=engine)
        
        users = [
            {"name": "Admin User", "email": "admin", "password": "Admin@2026", "role": "admin"},
            {"name": "Driver One", "email": "driver1", "password": "driver123", "role": "driver"},
            {"name": "Student One", "email": "student1", "password": "pass123", "role": "student"},
            {"name": "Staff Member", "email": "staff1", "password": "staff123", "role": "staff"},
            {"name": "Parent User", "email": "parent1", "password": "parent123", "role": "parent"}
        ]
        
        for user_data in users:
            exists = db.query(models.User).filter(models.User.email == user_data["email"]).first()
            if not exists:
                new_user = models.User(
                    name=user_data["name"],
                    email=user_data["email"],
                    password=get_password_hash(user_data["password"]),
                    role=user_data["role"]
                )
                db.add(new_user)
                print(f"Created user: {user_data['email']}")
        
        db.commit()
        print("Database seeding complete.")
    except Exception as e:
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
