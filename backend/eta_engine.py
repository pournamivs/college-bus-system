import math
import json
import requests

def snap_to_road(lat, lng):
    try:
        url = f"http://router.project-osrm.org/match/v1/driving/{lng},{lat}?radiuses=50"
        response = requests.get(url, timeout=2).json()
        if response.get("code") == "Ok" and response.get("tracepoints"):
            pt = response["tracepoints"][0]["location"]
            # returns snapped lat, lng
            return pt[1], pt[0]
    except Exception:
        pass
    return lat, lng

# Memory cache for smoothing speeds: { bus_id: [speed1, speed2, speed3] }
_speed_history = {}

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000  # radius of Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = math.sin(delta_phi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    res = R * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))
    return res * 1.3 # Apply 1.3 urban routing multiplier to approximate real travel distance

def get_smoothed_speed(bus_id: str, current_speed_mps: float) -> float:
    if bus_id not in _speed_history:
        _speed_history[bus_id] = []
    
    # Optional threshold: If less than 1 m/s, consider it 0 to avoid false ETA spikes
    clean_speed = current_speed_mps if current_speed_mps >= 1.0 else 0.0
    
    _speed_history[bus_id].append(clean_speed)
    if len(_speed_history[bus_id]) > 5:
        _speed_history[bus_id].pop(0)
        
    return sum(_speed_history[bus_id]) / len(_speed_history[bus_id])

def calculate_payload_eta(bus_id: str, lat: float, lng: float, current_speed_kh: float, route_stops_json: str):
    """
    Returns dict with keys: next_stop, distance_to_stop, eta_minutes, eta_status
    """
    if not route_stops_json:
        return None

    try:
        stops = json.loads(route_stops_json)
    except json.JSONDecodeError:
        return None

    next_stop = None
    dist_to_next = 0
    
    for stop in stops:
        dist = haversine(lat, lng, stop['lat'], stop['lng'])
        if dist > 50: # 50 meters radius marks a stop as 'passed'
            next_stop = stop
            dist_to_next = dist
            break
            
    if not next_stop:
        return {
            "next_stop": "Route Complete",
            "distance": 0,
            "eta_minutes": 0,
            "eta_status": "Arrived"
        }
        
    lat, lng = snap_to_road(lat, lng)
    smoothed_speed = get_smoothed_speed(bus_id, current_speed_kh)
    
    # Calculate ETA based on speed
    if smoothed_speed == 0:
        # If at a stop (distance < 100m but not fully passed)
        if dist_to_next < 100:
             return {
                 "next_stop": next_stop['name'],
                 "distance": round(dist_to_next),
                 "eta_minutes": 0,
                 "eta_status": "Boarding"
             }
        return {
            "next_stop": next_stop['name'],
            "distance": round(dist_to_next),
            "eta_minutes": -1,
            "eta_status": "Delayed / Traffic"
        }
        
    eta_seconds = dist_to_next / smoothed_speed
    eta_minutes = math.ceil(eta_seconds / 60)
    
    return {
        "next_stop": next_stop['name'],
        "distance": round(dist_to_next),
        "eta_minutes": eta_minutes,
        "eta_status": "Arriving Soon" if eta_minutes <= 2 else "On Route"
    }
