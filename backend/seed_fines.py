from database import SessionLocal
import models
from sqlalchemy.orm import Session

def seed_fines():
    db = SessionLocal()
    try:
        student = db.query(models.User).filter(models.User.email == "student1").first()
        if not student:
            print("Student not found")
            return

        # Add some demo fines
        fines = [
            models.Fine(student_id=student.id, amount=50.0, reason="Late Fee - Sept", status="unpaid"),
            models.Fine(student_id=student.id, amount=120.0, reason="Library Dues", status="unpaid"),
            models.Fine(student_id=student.id, amount=200.0, reason="ID Card Replacement", status="paid"),
        ]
        
        for f in fines:
            # Check if fine already exists to avoid duplicates
            exists = db.query(models.Fine).filter(
                models.Fine.student_id == f.student_id, 
                models.Fine.reason == f.reason
            ).first()
            if not exists:
                db.add(f)
        
        db.commit()
        print("Fines seeded successfully")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_fines()
