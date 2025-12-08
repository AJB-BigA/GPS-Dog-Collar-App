import time
import requests

BASE_URL = "https://api.249dogs.uk"   # <-- change if your server IP/port is different

def send_update(lat, lon,device_id="Xina"):
    try:
        # This matches: @app.post("/update") in your FastAPI app
        payload = {
            "device_id": device_id,
            "lat": lat,
            "lng": lon,       # <-- use lng to match the model
            "bat" : 98,
            "status" : False,
            "timestamp": None # let server fill it
        } # let server fill it
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
        lat -= 0.0001
        lon += 0.0001

        # wait 5 seconds
        time.sleep(5)

if __name__ == "__main__":
    main()
