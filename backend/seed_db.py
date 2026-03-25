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
            {"name": "Admin 1", "email": "admin", "password": "Admin@2026", "role": "admin"},
            {"name": "Admin 2", "email": "admin2", "password": "Admin@2026", "role": "admin"},
            {"name": "Driver 1", "email": "driver1", "password": "driver123", "role": "driver"},
            {"name": "Driver 2", "email": "driver2", "password": "driver123", "role": "driver"},
            {"name": "Driver 3", "email": "driver3", "password": "driver123", "role": "driver"},
            {"name": "Driver 4", "email": "driver4", "password": "driver123", "role": "driver"},
            {"name": "Student 1", "email": "student1", "password": "pass123", "role": "student", "assigned_stop": "Library"},
            {"name": "Student 2", "email": "student2", "password": "pass123", "role": "student", "assigned_stop": "Main Gate"},
            {"name": "Student 3", "email": "student3", "password": "pass123", "role": "student", "assigned_stop": "Hostel"},
            {"name": "Student 4", "email": "student4", "password": "pass123", "role": "student", "assigned_stop": "City Center"},
            {"name": "Student 5", "email": "student5", "password": "pass123", "role": "student", "assigned_stop": "Junction"},
            {"name": "Staff 1", "email": "staff1", "password": "pass123", "role": "staff"},
            {"name": "Staff 2", "email": "staff2", "password": "pass123", "role": "staff"},
            {"name": "Parent 1", "email": "parent1", "password": "pass123", "role": "parent"},
            {"name": "Parent 2", "email": "parent2", "password": "pass123", "role": "parent"},
            {"name": "Parent 3", "email": "parent3", "password": "pass123", "role": "parent"}
        ]
        
        for user_data in users:
            exists = db.query(models.User).filter(models.User.email == user_data["email"]).first()
            if not exists:
                new_user = models.User(
                    name=user_data["name"],
                    email=user_data["email"],
                    password=get_password_hash(user_data["password"]),
                    role=user_data["role"],
                    assigned_stop=user_data.get("assigned_stop")
                )
                db.add(new_user)
                print(f"Created user: {user_data['email']}")
        
        db.commit()
        
        # Link parents to students
        for i in range(1, 4):
            parent = db.query(models.User).filter(models.User.email == f"parent{i}").first()
            student = db.query(models.User).filter(models.User.email == f"student{i}").first()
            if parent and student:
                student.parent_id = parent.id
        db.commit()

        # Assign buses for drivers
        for i in range(1, 5):
            driver = db.query(models.User).filter(models.User.email == f"driver{i}").first()
            if driver:
                bus_exists = db.query(models.Bus).filter(models.Bus.name == f"Bus 10{i}").first()
                if not bus_exists:
                    new_bus = models.Bus(name=f"Bus 10{i}", number_plate=f"DEMO-10{i}", capacity=50, driver_id=driver.id)
                    db.add(new_bus)
                    
        db.commit()
        print("Database seeding complete.")
    except Exception as e:
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
