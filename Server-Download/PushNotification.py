import httpx
import jwt
import time 

TEAM_ID = "Team_Name"
KEY_ID = "Key_Id"
BUNDLE_ID = "com.yourapp.249dogs" # your app's bundle ID
APNS_KEY = """-----BEGIN PRIVATE KEY-----
YOUR_P8_KEY_CONTENTS_HERE
-----END PRIVATE KEY-----"""


def sendNotification(token: str, fence_name: str, id: str):
    """sends notification to devices"""
    authToken = jwt.encode(
        payload = {"iss" : TEAM_ID, "iat" : time.time()},
        key = APNS_KEY, 
        algorithm="ES256",
        headers = {"kid" : KEY_ID}

    )
    url = f"https://api.push.apple.com/3/device/{token}"

    headers = { "authorization" : f"bearer {authToken}", 
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



