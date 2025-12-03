//
//  Helper.hpp
//  GPS-Helper-Function
//
//  Created by Austin Baker on 3/12/2025.
//

#ifndef Helper_HPP
#define Helper_HPP

#include <iostream>
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>


std::pair<String,String> getLatAndLng(const String& s);
bool checkIfSatLock(const String& s);
String createPayload(const String& lat, const String& lng, const String& bat, bool status);
void sendPacket(const String& payload, WiFiClientSecure& wifi, HttpClient& client);
String formatBattery(String&);

#endif /* Helper_hpp */
