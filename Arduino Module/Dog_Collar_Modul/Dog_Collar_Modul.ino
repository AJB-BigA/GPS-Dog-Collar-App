#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <Arduino.h>
#include "Helper.hpp"

//internet username and password
const char* ssid = "TelstraE26C84";
const char* password = "8df5zb87z3";

//api server probably shouldnt add these to github xd
const char server[] = "api.249dogs.uk";
int port = 443;

WiFiClientSecure wifi; 
HttpClient client(wifi, server, port);

bool modemStatus = false;

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
    return false;
  }else{
    return true;
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
  
  WiFi.begin(ssid, password);

}

unsigned long lastGNSS = 0;

void loop() {
  if(connectToWifi()){
    delay(1000);
    //checks if the modem is on and turns it off
    if(modemStatus){
      toggleModem();
    }
    
  }else{
    //checks if the modem is on and turns it on if its not
    if(!modemStatus){
      toggleModem();
    }
    
    String output = "";
    if (millis() - lastGNSS > 5000) {
      lastGNSS = millis();
      Serial.print("AT+CGNSINF");
    }
    output = readOutput();

    if (output != ""){
      auto cords = getLatAndLng(output);
      sendAT("AT+CBC");
      String battery = readOutput();
      String bPercentage = formatBattery(battery);
      String payload = createPayload(cords.first, cords.second, bPercentage, connectToWifi());
      sendPacket(payload, wifi, client);
    }
      delay(5000);
    }

}
