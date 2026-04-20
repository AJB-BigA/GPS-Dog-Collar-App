#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <Arduino.h>
#include "Helper.hpp"
#define TINY_GSM_MODEM_SIM7080
#include <TinyGsmClient.h>
#include <WiFi.h>
#include "secrets.h"

//internet username and password
const char* ssid = WifiSSID;
const char* password = WifiPassword;

//api server probably shouldnt add these to github xd
const char server[] = serverHTML;
int port = 443;
//set up wifi routing
WiFiClientSecure wifi; 
HttpClient wifiClient(wifi, server, port);

//set up simcard
TinyGsm modem(Serial1);
TinyGsmClientSecure client(modem);
HttpClient simClient(client, server, port);


bool modemStatus = false;
bool satLoc = false;
bool safeCords = false; 


String sendAT(const char *cmd, unsigned long waitMs = 2000){
  // Clear buffer first
  while(Serial1.available()) {
    Serial1.read();
  }
  
  Serial.print(">> ");
  Serial.println(cmd);
  Serial1.print(cmd);
  Serial1.print("\r\n");
  
  String output = "";
  unsigned long startTime = millis();
  
  // Keep reading until timeout OR we see "OK" or "ERROR"
  while(millis() - startTime < waitMs) {
    while(Serial1.available()) {
      char c = Serial1.read();
      output += c;
      Serial.print(c);
      startTime = millis();  // Reset timeout when we receive data
    }
    
    // Check if response is complete
    if(output.indexOf("OK") >= 0 || output.indexOf("ERROR") >= 0) {
      break;
    }
  }
  
  Serial.println();
  return output;
}


//pusles the modem to turn it on or off
void pulseModem(){
  pinMode(14, OUTPUT);
  digitalWrite(14, HIGH);
  delay(1500);
  digitalWrite(14,LOW);
  delay(5000);
}

//this function will toggle the modem on and off
void toggleModem(bool ON, int maxRetries = 5) {
  if(maxRetries <= 0) {
    Serial.println("ERROR: Max retries reached, modem not responding");
    modemStatus = false;
    return;
  }
  String status = sendAT("AT");
  
  
  if(ON) {
    if(status.indexOf("OK") >= 0) {
      modemStatus = true;
      Serial.println("Modem is ON");
      return;
    } else {
      Serial.println("===turning on modem=== Retries left: " + String(maxRetries));
      pulseModem();
      toggleModem(true, maxRetries - 1);  // Decrement retries
    }
  } else {
    if(status.indexOf("OK") >= 0) {
      Serial.println("===turning off modem===");
      pulseModem();
      toggleModem(false, maxRetries - 1);  // Decrement retries
    } else {
      modemStatus = false;
      Serial.println("Modem is OFF");
      return;
    }
  }
}

//checks to see if the wifi is connected
bool connectToWifi(){
    if (WiFi.status() != WL_CONNECTED){
      WiFi.begin(ssid, password);
      delay(10000);
    }
    return(WiFi.status() == WL_CONNECTED);
}

//runs the protocall for connecting to the cell tower
void connectToTower(){
  modem.restart();
  modem.waitForNetwork();
  modem.gprsConnect("simbase");
  while(!modem.isGprsConnected()){
    delay(3000);
    modem.gprsConnect("simbase");
    Serial.print("Failed to connect to tower");
  }
  Serial.print("Connected and sent");
}

//returns the percentage of the battery
String getBatteryPercentage(){
  String battery = sendAT("AT+CBC");; 
  delay(1000);
  String bPercentage = formatBattery(battery);
  Serial.println("Batery% : " + bPercentage);
  return bPercentage;
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  delay(2000);

  //turn on the serial output
  Serial1.setRX(1);
  Serial1.setTX(0);
  Serial1.begin(115200);
  delay(1000);
}

unsigned long lastGNSS = 0;
unsigned long heartbeat = 0;
int i = 0;
String gpsOutput = "";
void loop() {
  if(connectToWifi()){
    //checks if the modem is on and turns it off
    if(modemStatus){
      toggleModem(false);
    }
    //every 5 mins turn the modem on and send the battery %
    if (millis() - heartbeat > 300000) {
      toggleModem(true);
      delay(2000);
      String bPercentage = getBatteryPercentage();
      String payload = createPayload("-34.7528185047608", "150.4537067701276", bPercentage, true);
      wifi.setInsecure();
      sendPacket(payload, wifiClient);
      heartbeat = millis();
    }
  }else{
      //checks if the modem is on and turns it on if its not
      if(!modemStatus){
        toggleModem(true);
        delay(3000);
      }
      //every 5 seconds gets a new satilight number
      if (millis() - lastGNSS > 5000) {
        sendAT("AT+CGNSPWR=1"); 
        lastGNSS = millis();
        gpsOutput = sendAT("AT+CGNSINF", 5000);

        //run checks on the output 
        satLoc = checkIfSatLock(gpsOutput);
        Serial.print(gpsOutput);
        safeCords = checkIfSafe(gpsOutput);
      }
      

      if(satLoc && safeCords){
        Serial.print("sat lock");
        auto cords = getLatAndLng(gpsOutput);
        String bPercentage = getBatteryPercentage();
        Serial.println("Batery% : " + bPercentage);

        String payload = createPayload(cords.first, cords.second,bPercentage,connectToWifi());
        Serial.print(payload);
        //turn off the gps
        sendAT("AT+CGNSPWR=0");

        //BUG AlERT THE SIM MAY NOT ME ON
        //turn the sim card on
        connectToTower();
        sendPacket(payload, simClient);
        sendAT("AT+CGNSPWR=1");
      }

      //turn the checks back off after each cycle
      satLoc = false; 
      safeCords = false; 
    }
}
