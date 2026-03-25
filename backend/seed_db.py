import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import SessionLocal
import models
from routes.auth import get_password_hash

def seed():
    db = SessionLocal()
    try:
        # Check if admin exists
        admin = db.query(models.User).filter(models.User.email == "admin@example.com").first()
        if not admin:
            new_admin = models.User(
                name="Admin",
                email="admin@example.com",
                password=get_password_hash("Admin@2026"),
                role="admin"
            )
            db.add(new_admin)
        
        # Check if student exists
        student = db.query(models.User).filter(models.User.email == "student1@example.com").first()
        if not student:
            new_student = models.User(
                name="Student 1",
                email="student1@example.com",
                password=get_password_hash("pass123"),
                role="student",
                assigned_stop="College Main Gate"
            )
            db.add(new_student)

        # Check if driver exists
        driver = db.query(models.User).filter(models.User.email == "driver1@example.com").first()
        if not driver:
            new_driver = models.User(
                name="Driver 1",
                email="driver1@example.com",
                password=get_password_hash("driver123"),
                role="driver"
            )
            db.add(new_driver)
        
        db.commit()
    except Exception as e:
        print(f"Seed error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
    print("Database seeded successfully")
