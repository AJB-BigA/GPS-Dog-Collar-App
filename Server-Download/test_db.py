import time
import requests

BASE_URL = "http://192.168.0.247:8000"   # <-- change if your server IP/port is different

def send_update(lat, lon,device_id="Nala"):
    try:
        # This matches: @app.post("/update") in your FastAPI app
        payload = {
            "device_id": device_id,
            "lat": lat,
            "lng": lon,       # <-- use lng to match the model
            "bat": 97,
            "timestamp": None # let server fill it
        }
        resp = requests.post(
            f"{BASE_URL}/api/location",
            json=payload,
            timeout=5,
        )
        resp.raise_for_status()
        print("Update OK:", resp.json())
    except Exception as e:
        print("Update failed:", e)

def main():
    # starting position (example coords)
    lat = -34.7529061596312
    lon = 150.4538029581605

    while True:
        send_update(lat, lon)

        # change slightly each time to simulate movement
        lat += 0.0001
        lon += 0.0001

        # wait 5 seconds
        time.sleep(5)

if __name__ == "__main__":
    main()
