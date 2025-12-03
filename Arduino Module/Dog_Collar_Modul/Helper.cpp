#include "Helper.hpp"
#include <iostream>
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>

using namespace std;
/*

Function returns the lat and lng from the data given to it by the gps
input looks like -> 
AT+CGNSINF
+CGNSINF: 1,1,20251203,095433.000,-33.889120,151.199950,45.6,0.12,270.3,1,0.9,1.3,0.7,0,10,7,3,0,38,1.2,1.8

OK

or

 AT+CGNSINF
 +CGNSINF: 1,0,,,,,,,,,,,,,,,,,,,

 OK

 parm -> String: CGNSINF output
 return pair<String,String>: lat, lng 
 */
pair<String, String> getLatAndLng(const String& s){
    int i = 0;
    int j = 0;
    String lat;
    String lng;
    //scan all until reach the comma required
    while(j < 4){
        if (s[i] == ','){
            j++;
        }
        i++;
    }
    //gets the lat
    while(s[i] != ','){
        lat += s[i];
        i++;
    }
    i++;
    //gets the lng
    while(s[i] != ','){
        lng += s[i];
        i++;
    }
    return make_pair(lat, lng);
}
/*
This function checks to see if the gps has a fix on its position
need to check the second output
it will be 1 or 0
*/
bool checkIfSatLock(const String& s){
    int i = 0;
    while (s[i] != ','){
        i++;
    }
    i++;
    if(s[i] == '0'){
        return false;
    }else {
        return true;
    }
}
/*
creates the payload
parm -> String: lat
        String: lng
        String: batery percentage
        bool: status (connected to wifi)
*/
String createPayload(const String& lat, const String& lng, const String& bat, bool status){
    String payload = "{";
    payload += "\"device_id\":\"Nala\",";
    payload += "\"lat\":"+lat+",";
    payload += "\"lng\":"+lng+",";
    payload += "\"bat\":"+bat+",";
    payload += "\"status\":"+String(status? "true":"flase")+"";
    payload += "}";
    return payload;
}

/*
parm -> String : Payload
return -> void
sends the packet to the server 
*/
void sendPacket(const String& payload, WiFiClientSecure& wifi, HttpClient& client){
    wifi.setInsecure();
    String path = "/api/location";
    client.beginRequest();
    client.post(path);
    client.sendHeader("Content-Type", "application/json");
    client.sendHeader("Content-Length", payload.length());
    client.beginBody();
    client.print(payload);
    client.endRequest();
}

/* 
parm -> String : output from the waveshare
return -> String : battery percentage 
*/
String formatBattery(String& s){ 
    String battery; 
    size_t pos = s.indexOf(',');
    if (pos < 0 || pos + 1 >= s.length()) {
        return "-1";   // malformed line
    }
    pos++;
    while(s[pos]!= ','){
        battery += s[pos];
        pos++; 
    }
    return battery;
}
