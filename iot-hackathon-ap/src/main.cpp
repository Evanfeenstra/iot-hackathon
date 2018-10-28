#include <Arduino.h>
#include "IPAddress.h"
#include <ESPAsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <ESP8266WiFi.h>

// pio lib install "ESP Async WebServer"

// prototypes
void pollSerial();
void onWsEvent(AsyncWebSocket * server, AsyncWebSocketClient * client, AwsEventType type, void * arg, uint8_t *data, size_t len);

// objects
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");
IPAddress myIP;

// constants
const char * hostName = "trident";
const char * password = "password";
const int channel = 9;

void setup() {
  Serial.begin(115200);

  // MAKE ACCESS POINT
  WiFi.softAP(hostName, password, channel);

  // CONFIG ACCESS POINT
  IPAddress ip(216,216,216,216);
  IPAddress gateway(1,2,3,4);
  IPAddress subnet(255,255,255,0);
  WiFi.softAPConfig(ip, gateway, subnet);

  server.on("/hello", HTTP_GET, [](AsyncWebServerRequest *request){
    Serial.println("hello");
    request->send(200, "text/plain", "Hello World");
  });

  server.begin();
  ws.onEvent(onWsEvent);
  server.addHandler(&ws);
}

void loop() {
    pollSerial();
}

void sendWire(const char* message){
  Serial.printf(message);
}

void onWsEvent(AsyncWebSocket * server, AsyncWebSocketClient * client, AwsEventType type, void * arg, uint8_t *data, size_t len){
  if(type == WS_EVT_CONNECT){
    //Serial.printf("ws[%s][%u] connect\n", server->url(), client->id());
    client->printf("{\"type\":\"CONNECTION\",\"msg\":\"Hello Client %u :)\",\"id\":%u}", client->id(), client->id());
    //client->ping();
  } else if(type == WS_EVT_DISCONNECT){
    //Serial.printf("ws[%s][%u] disconnect: %u\n", server->url(), client->id());
  } else if(type == WS_EVT_ERROR){
    //Serial.printf("ws[%s][%u] error(%u): %s\n", server->url(), client->id(), *((uint16_t*)arg), (char*)data);
  } else if(type == WS_EVT_PONG){
    //Serial.printf("ws[%s][%u] pong[%u]: %s\n", server->url(), client->id(), len, (len)?(char*)data:"");
  } else if(type == WS_EVT_DATA){
    AwsFrameInfo * info = (AwsFrameInfo*)arg;
    String msg = "";
    if(info->final && info->index == 0 && info->len == len){
      //the whole message is in a single frame and we got all of it's data
      //Serial.printf("ws[%s][%u] %s-message[%llu]: ", server->url(), client->id(), (info->opcode == WS_TEXT)?"text":"binary", info->len);

      if(info->opcode == WS_TEXT){
        for(size_t i=0; i < info->len; i++) {
          msg += (char) data[i];
        }
      } else {
        char buff[3];
        for(size_t i=0; i < info->len; i++) {
          sprintf(buff, "%02x ", (uint8_t) data[i]);
          msg += buff ;
        }
      }
      //Serial.printf("%s\n",msg.c_str());
      sendWire(msg.c_str());

      if(info->opcode == WS_TEXT)
        //client->text(msg);
        ws.textAll(msg);
      else
        client->binary("I got your binary message");
    } else {
      //message is comprised of multiple frames or the frame is split into multiple packets
      if(info->index == 0){
        //if(info->num == 0)
          //Serial.printf("ws[%s][%u] %s-message start\n", server->url(), client->id(), (info->message_opcode == WS_TEXT)?"text":"binary");
        //Serial.printf("ws[%s][%u] frame[%u] start[%llu]\n", server->url(), client->id(), info->num, info->len);
      }
      //Serial.printf("ws[%s][%u] frame[%u] %s[%llu - %llu]: ", server->url(), client->id(), info->num, (info->message_opcode == WS_TEXT)?"text":"binary", info->index, info->index + len);

      if(info->opcode == WS_TEXT){
        for(size_t i=0; i < info->len; i++) {
          msg += (char) data[i];
        }
      } else {
        char buff[3];
        for(size_t i=0; i < info->len; i++) {
          sprintf(buff, "%02x ", (uint8_t) data[i]);
          msg += buff ;
        }
      }
      //Serial.printf("%s\n",msg.c_str());

      if((info->index + len) == info->len){
        //Serial.printf("ws[%s][%u] frame[%u] end[%llu]\n", server->url(), client->id(), info->num, info->len);
        if(info->final){
          //Serial.printf("ws[%s][%u] %s-message end\n", server->url(), client->id(), (info->message_opcode == WS_TEXT)?"text":"binary");
          //if(info->message_opcode == WS_TEXT)
            //client->text("I got your text message");
          //else
            //client->binary("I got your binary message");
        }
      }
    }
  }
}

void pollSerial() {
  String buff;
  while (1 < Serial.available()) {
    char c = Serial.read();
    buff += c;
  }
  if(Serial.available()==1){
    char x = Serial.read();
    buff += x;
    ws.textAll(buff);
    // if(buff.substring(0,4)=="http"){
    // }
  }
}
