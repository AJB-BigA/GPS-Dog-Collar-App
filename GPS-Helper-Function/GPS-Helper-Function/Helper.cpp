//
//  Helper.cpp
//  GPS-Helper-Function
//
//  Created by Austin Baker on 3/12/2025.
//

#include "Helper.hpp"
#include <iostream>

using namespace std;

//this function returns the lat or the long depending on how many ',' are to be counted
//input looks like -> 
/*
AT+CGNSINF
+CGNSINF: 1,1,20251203,095433.000,-33.889120,151.199950,45.6,0.12,270.3,1,0.9,1.3,0.7,0,10,7,3,0,38,1.2,1.8

OK
*/
//or
/*
 AT+CGNSINF
 +CGNSINF: 1,0,,,,,,,,,,,,,,,,,,,

 OK
 */
pair<string, string> getLatAndLong(string s){
    int i = 0;
    int j = 0;
    string lat;
    string lng;
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
bool checkIfSatLock(string s){
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

string createPayload(string lat, string lng, string bat, bool status){
    string payload = "{";
    payload += "\"device_id\":\"Nala\",";
    payload += "\"lat\":"lat",";
    payload += "\"lng\":'lng',";
    payload += "\"bat\":"lng",";
    payload += "\"status\":"status"";
    payload += "}";

    return payload;
}

