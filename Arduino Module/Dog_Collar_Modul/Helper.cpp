#include "Helper.hpp"
#include <iostream>
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <vector>
#define TINY_GSM_MODEM_SIM7080
#define TINY_GSM_SSL_CLIENT_AUTHENTICATION TINY_GSM_SSL_CLIENT_AUTHENTICATION_NONE
#include <TinyGsmClient.h>

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

pair<string,string> getLatAndLng(const string& s){

    string data;
    vector<string> fields;
    istringstream stream(s);
    
    while(getline(stream, data, ',')){
        fields.push_back(data);
    }
    return make_pair(fields[3],fields[4]);
}


//checks the validity of the gps cords 
bool checkIfSafe(const String& s){
    auto count(s.begin(), s.end(), ',') + 1;
    if(s > 56 & count < 5 ){
        return true;
    }
    else {return false;}
    }
}

/*
This function checks to see if the gps has a fix on its position
need to check the second output
it will be 1 or 0
*/
bool checkIfSatLock(const String& s){
    int i = s.indexOf(',');
    if( i < 0 || i + 1 >= s.length()){
        return false;
    }
    return (s[i+1] == '1');
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
    payload += "\"status\":"+String(status? "true":"false")+"";
    payload += "}";
    return payload;
}

/*
parm -> String : Payload
return -> void
sends the packet to the server 
*/
void sendPacket(const String& payload, HttpClient& client){
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
    int pos = s.indexOf(',');
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
