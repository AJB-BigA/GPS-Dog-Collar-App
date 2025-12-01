#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <Arduino.h>

const char* ssid = "TelstraE26C84";
const char* password = "8df5zb87z3";

const char server[] = "api.249dogs.uk";
int port = 443;

const int PWRKEY = 14;

WiFiClientSecure wifi; 
HttpClient client(wifi, server, port);


void sendAT(const char *cmd, unsigned long waitMs = 500){
  Serial.print(">> ");
  Serial.println(cmd);
  Serial1.print(cmd);
  Serial1.print("\r\n");
  delay(waitMs);

  while (Serial1.available()){
    char c = Serial1.read();
    Serial.write(c);
  }
  Serial.println();
  }

  

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  delay(2000);

  pinMode(14, OUTPUT);
  digitalWrite(14, HIGH);
  delay(1500);
  digitalWrite(14,LOW);

  delay(3000);


  //turn on the serial output
  Serial1.setRX(1);
  Serial1.setTX(0);
  Serial1.begin(115200);

  delay(1000);

  sendAT("AT",500);

  //turn GNSS power on
  //AT+CGNSPWR = 1 -> power on 
  sendAT("AT+CGNSPWR = 1");

  sendAT("AT+CGNSINF");
  
  WiFi.begin(ssid, password);
  Serial.print("Connecting to wifi : ");
  while (WiFi.status() != WL_CONNECTED){
    delay(500);
    Serial.print(".");
  }
  Serial.print("connected!!!!\n");
  wifi.setInsecure();
  // Example HTTP POST
  String path = "/api/location";
  String payload = "{";
    payload += "\"device_id\":\"Nala\",";
    payload += "\"lat\":-33.87,";
    payload += "\"lng\":151.21,";
    payload += "\"bat\":90,";
    payload += "\"status\":true";
    payload += "}";

  client.beginRequest();
  client.post(path);
  client.sendHeader("Content-Type", "application/json");
  client.sendHeader("Content-Length", payload.length());
  client.beginBody();
  client.print(payload);
  client.endRequest();

  int statusCode = client.responseStatusCode();
  String response = client.responseBody();

  Serial.print("Status: ");
  Serial.println(statusCode);
  Serial.print("Body: ");
  Serial.println(response);
}

unsigned long lastGNSS = 0;
void loop() {
  
  if(millis() - lastGNSS > 5000) {
    lastGNSS = millis();
    sendAT("AT+CGNSINF", 1000);
  }


  while (Serial1.available()){
    char c = Serial1.read();
    Serial.write(c);
  }
}
