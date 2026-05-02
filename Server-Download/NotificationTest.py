import time
import requests

BASE_URL = "https://api.249dogs.uk"   # <-- change if your server IP/port is different

def send_update(device_id="Nala"):
    try:
        # This matches: @app.post("/update") in your FastAPI app
        payload = {
            "device_id": device_id,
        }
        resp = requests.post(
            f"{BASE_URL}/api/lostWifi",
            json=payload,
            timeout=5,
        )
        resp.raise_for_status()
        print("Update OK:", resp.json())
    except Exception as e:
        print("Update failed:", e)

def main():
    # starting position (example coords)

    while True:
        send_update()
        # wait 5 seconds
        time.sleep(5)

if __name__ == "__main__":
    main()
