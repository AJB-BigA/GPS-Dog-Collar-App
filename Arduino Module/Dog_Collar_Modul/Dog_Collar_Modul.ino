#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <Arduino.h>
#include "Helper.hpp"
#define TINY_GSM_MODEM_SIM7080
#include <TinyGsmClient.h>

//internet username and password
const char* ssid = "TelstraE26C84";
const char* password = "8df5zb87z3";

//api server probably shouldnt add these to github xd
const char server[] = "api.249dogs.uk";
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

String readModemResponse(unsigned long timeoutMs = 2000) {
  String resp = "";
  unsigned long start = millis();

  while (millis() - start < timeoutMs) {
    while (Serial1.available()) {
      char c = Serial1.read();
      resp += c;
    }
  }
  return resp;
}

void sendAT(const char *cmd, unsigned long waitMs = 500){
  Serial.println(cmd);
  Serial1.print(cmd);
  delay(waitMs);

  String resp = readModemResponse(waitMs);
  Serial.println(resp);   // print full response block
  }

String readOutput(){
  String output;
   while (Serial1.available()) {
      char c = Serial1.read();
      output += c;
    }
    return output;
}

//returns the percentage of the battery
String getBatteryPercentage(){
  String output; 
  sendAT("AT+CBC");
  delay(1000);
  String battery = readOutput();
  String bPercentage = formatBattery(battery);
  return bPercentage;
}

//this function will toggle the modem on and off
void toggleModem(){
  pinMode(14, OUTPUT);
  digitalWrite(14, HIGH);
  delay(1500);
  digitalWrite(14,LOW);
  delay(3000);
  modemStatus = !modemStatus;
  //turn GNSS power on
  //AT+CGNSPWR = 1 -> power on 
  sendAT("AT+CGNSPWR=1");
  
}

//checks to see if the wifi is connected
bool connectToWifi(){
    if (WiFi.status() != WL_CONNECTED){
      WiFi.begin(ssid, password);
      delay(10000);
    }
    return(Wifi.status() == WL_CONNECTED);
}

//runs the protocall for connecting to the cell tower
void connectToTower(){
  modem.restart();
  modem.waitForNetwork();
  modem.gprsConnect("Insert text here");
  while(!modem.gprsConnected()){
    delay(3000);
    modem.gprsConnect("Insert text here");
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  toggleModem();
  delay(2000);

  //turn on the serial output
  Serial1.setRX(1);
  Serial1.setTX(0);
  Serial1.begin(115200);

  delay(1000);
}

unsigned long lastGNSS = 0;
unsigned long heartbeat = 0;

void loop() {
  if(connectToWifi()){
    //checks if the modem is on and turns it off
    if(modemStatus){
      toggleModem();
    }
    //every 5 mins turn the modem on and send the battery %
    if (millis() - heartbeat > 300000) {
      toggleModem();
      delay(2000);
      String bPercentage = getBatteryPercentage();
      String payload = createPayload("-34.7528185047608", "150.4537067701276", bPercentage, true);
      sendPacket(payload, wifiClient);
      heartbeat = millis();
    }
  }else{
      //checks if the modem is on and turns it on if its not
      if(!modemStatus){
        toggleModem();
        delay(3000);
      }
      String output = "";
      if (millis() - lastGNSS > 5000) {
        lastGNSS = millis();
        Serial1.print("AT+CGNSINF");
      }
      output = readOutput();
      satLoc = checkIfSatLock(output);
      if(satLoc){
        auto cords = getLatAndLng(output);
        String bPercentage = getBatteryPercentage();
        String payload = createPayload(cords.first, cords.second,bPercentage , connectToWifi());

        //turn off the gps
        sendAT("AT+CGNSPWR=0");

        //turn the sim card on
        connectToTower();
        sendPacket(payload, simClient);
        sendAT("AT+CGNSPWR=1");
      }
    }
}
