import os
import re
import socket
import subprocess
import sys
import time

def get_local_ip():
    try:
        # Create a dummy socket to find the default route IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def update_api_constants(ip):
    path = os.path.join("lib", "core", "constants", "api_constants.dart")
    if not os.path.exists(path):
        print(f"⚠️ Warning: {path} not found.")
        return

    print(f"📝 Updating {path} with IP: {ip}")
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    content = re.sub(r'http://[\d\.]+:8000', f'http://{ip}:8000', content)
    content = re.sub(r'ws://[\d\.]+:8000', f'ws://{ip}:8000', content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def run_db_seed():
    print("🚀 Seeding Database...")
    try:
        subprocess.run([sys.executable, "seed_db.py"], cwd="backend", check=True)
    except Exception as e:
        print(f"❌ DB Seed Failed: {e}")

def get_mobile_device():
    print("🔍 Searching for mobile devices...")
    try:
        result = subprocess.run(["flutter", "devices"], capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if "mobile" in line.lower() or "android" in line.lower() or "ios" in line.lower():
                # Line format: RMX3686 (mobile) • RKKVUS4LEYT4K765 • android-arm64 • ...
                parts = line.split("•")
                if len(parts) > 1:
                    return parts[1].strip()
    except Exception:
        pass
    return None

def main():
    print("🌟 TrackMyBus Ultimate Startup 🌟")
    
    # 1. IP Detection
    ip = get_local_ip()
    print(f"✅ Local IP: {ip}")
    update_api_constants(ip)
    
    # 2. Seed DB
    run_db_seed()
    
    # 3. Start Backend in a new window
    print("🚀 Starting Backend Server...")
    cmd = f'start "TrackMyBus Backend" /D "{os.path.join(os.getcwd(), "backend")}" uvicorn main:app --host 0.0.0.0 --port 8000'
    os.system(cmd)
    
    # 4. Start Flutter
    device_id = get_mobile_device()
    print("📱 Launching Flutter App...")
    
    flutter_cmd = ["flutter", "run"]
    if device_id:
        print(f"📍 Targeting Device: {device_id}")
        flutter_cmd.extend(["-d", device_id])
    
    try:
        subprocess.run(flutter_cmd)
    except KeyboardInterrupt:
        print("\n👋 Shutdown requested.")

if __name__ == "__main__":
    main()
