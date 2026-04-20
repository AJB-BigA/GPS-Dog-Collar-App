#include "Helper.hpp"
#include <iostream>
#include <Arduino.h>
#include <WiFi.h>
#include <sstream>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <vector>
#include <algorithm>
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

pair<String,String> getLatAndLng(const String& s){
    string stdS = s.c_str();      // convert Arduino String → std::string here
    string data;
    vector<string> fields;
    istringstream stream(stdS);   // istringstream needs std::string, use stdS
    
    while(getline(stream, data, ',')){
        fields.push_back(data);
    }
    if(fields.size() < 6) return make_pair(String(""), String(""));
    return make_pair(String(fields[3].c_str()), String(fields[4].c_str()));
}


//checks the validity of the gps cords 
 bool checkIfSafe(const String& s){
    string stdStr = s.c_str();
    auto numSections = count(stdStr.begin(), stdStr.end(), ',') + 1;
    if(s.length() > 56 && numSections >= 5){
        return true;
    }
    else { return false; }
    return false;
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

    // Drain the response or the next call may misbehave
    int statusCode = client.responseStatusCode();
    client.skipResponseHeaders();
    // optionally: client.responseBody() if you care about the body
    client.stop(); // if you want a clean close each time
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
