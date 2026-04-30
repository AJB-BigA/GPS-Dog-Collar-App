import httpx
import jwt
import time 
import os
from dotenv import load_dotenv

load_dotenv()

TEAM_ID = os.getenv("APNS_KEY_ID")
KEY_ID = os.getenv("APNS_TEAM_ID")
BUNDLE_ID = os.getenv("BUNDLE_ID_APP")
APNS_KEY = os.getenv("APNS_AUTH_KEY_PATH")

def send_notification(token: str, fence_name: str, id: str):
    """sends notification to devices"""
    auth_token = jwt.encode(
        payload = {"iss" : TEAM_ID, "iat" : time.time()},
        key = APNS_KEY, 
        algorithm="ES256",
        headers = {"kid" : KEY_ID}

    )
    url = f"https://api.push.apple.com/3/device/{token}"

    headers = { "authorization" : f"bearer {auth_token}", 
    "apns-topic": BUNDLE_ID,
    "apns-push-type" : "alert",
    }
    payload = {
        "aps": {
            "alert": {
                "title": f"{id} crossed a boundry",
                "body": f"{fence_name} boundary crossed"
            },
            "sound": "default"
        }
    }
    with httpx.Client(http2 = True) as client:
        response = client.post(url, json=payload, headers=headers)
        print(response.status_code)



def send_warning(token: str, collar_id:str):
    """Sends the notification to the devices"""
    auth_token = jwt.encode(
    payload = {"iss" : TEAM_ID, "iat" : time.time()},
    key = APNS_KEY,
    algorithm="ES256",
    headers = {"kid" : KEY_ID}

    )
    url = f"https://api.push.apple.com/3/device/{token}"

    headers = { "authorization" : f"bearer {auth_token}",
    "apns-topic": BUNDLE_ID,
    "apns-push-type" : "alert",
    }
    payload = {
        "aps": {
            "alert": {
                "title": f"{collar_id} has left wifi range",
                "body": f"Be carefull {collar_id} might be woundering her location will be updated soon"
            },
            "sound": "default"
        }
    }
    with httpx.Client(http2 = True) as client:
        response = client.post(url, json=payload, headers=headers)
        print(response.status_code)