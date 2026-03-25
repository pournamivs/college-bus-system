import os
import razorpay

RAZORPAY_KEY = os.getenv("RAZORPAY_KEY", "rzp_test_change_me")
RAZORPAY_SECRET = os.getenv("RAZORPAY_SECRET", "change_me_secret")

client = razorpay.Client(auth=(RAZORPAY_KEY, RAZORPAY_SECRET))

def create_order(amount_in_dollars: float):
    # Convert dollars to cents/paise
    amount_in_cents = int(amount_in_dollars * 100)
    data = {
        "amount": amount_in_cents,
        "currency": "USD",
        "receipt": "trackmybus_receipt",
        "payment_capture": 1
    }
    order = client.order.create(data=data)
    return order["id"]

def verify_payment_signature(razorpay_order_id, razorpay_payment_id, razorpay_signature):
    try:
        client.utility.verify_payment_signature({
            'razorpay_order_id': razorpay_order_id,
            'razorpay_payment_id': razorpay_payment_id,
            'razorpay_signature': razorpay_signature
        })
        return True
    except razorpay.errors.SignatureVerificationError:
        return False
