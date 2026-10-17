#include <DHT.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

// -------------------
// ПІНИ
// -------------------
#define PUMP1 5
#define PUMP2 18
#define PUMP3 19
#define PUMP4 21

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

#define WATER_SENSOR 25
#define SOIL1 32 
#define SOIL2 33
#define SOIL3 34
#define SOIL4 35
#define LIGHT_SENSOR 23

// RGB (перша лампа)
#define RGB_RED   26
#define RGB_GREEN 27
#define RGB_BLUE  14

// RGB STRIP (друга стрічка)
#define STRIP_R 15 //4
#define STRIP_G 13 //5
#define STRIP_B 22 //-3 

#define SOIL_WET 1200
#define SOIL_DRY 3200

// ---- UUID ----
#define SERVICE_UUID "12345678-1234-1234-1234-123456789ABC"
#define CHARACTERISTIC_UUID_DATA "12345678-1234-1234-1234-123456789ABD"
#define CHARACTERISTIC_UUID_CONTROL "12345678-1234-1234-1234-123456789ABE"

BLECharacteristic *pDataCharacteristic;
BLECharacteristic *pControlCharacteristic;
bool deviceConnected = false;

// ---- СТАНИ ----
bool relayStates[4] = {false, false, false, false};
int relayPins[4] = {PUMP1, PUMP2, PUMP3, PUMP4};

int rgbPins[3] = {RGB_RED, RGB_GREEN, RGB_BLUE};
int rgbValues[3] = {0, 0, 0};
bool rgbEnabled = false;

int stripPins[3] = {STRIP_R, STRIP_G, STRIP_B};
int stripValues[3] = {0, 0, 0};
bool stripEnabled = false;

// -------------------
// BLE CALLBACKS
// -------------------
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("✅ BLE підключено");
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("❌ BLE відключено");
    BLEDevice::startAdvertising();
  }
};

class ControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {

    std::string value = pCharacteristic->getValue();
    if (value.length() == 0) return;

    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, value);
    if (error) return;

    const char* type = doc["type"];

    // ---- RELAY ----
    if (strcmp(type, "relay") == 0) {
      int index = doc["index"];
      bool state = doc["state"].as<bool>();

      if (index >= 0 && index < 4) {
        digitalWrite(relayPins[index], state ? HIGH : LOW);
        relayStates[index] = state;
      }
    }

    // ---- RGB ----
    if (strcmp(type, "rgb") == 0) {

      if (doc.containsKey("enabled"))
        rgbEnabled = doc["enabled"].as<bool>();

      if (doc.containsKey("r"))
        rgbValues[0] = constrain(doc["r"].as<int>(), 0, 255);

      if (doc.containsKey("g"))
        rgbValues[1] = constrain(doc["g"].as<int>(), 0, 255);

      if (doc.containsKey("b"))
        rgbValues[2] = constrain(doc["b"].as<int>(), 0, 255);

      int r = rgbEnabled ? (255 - rgbValues[0]) : 255;
      int g = rgbEnabled ? (255 - rgbValues[1]) : 255;
      int b = rgbEnabled ? (255 - rgbValues[2]) : 255;

      ledcWrite(0, r);
      ledcWrite(1, g);
      ledcWrite(2, b);
    }

    // ---- STRIP ----
    if (strcmp(type, "strip") == 0) {

      if (doc.containsKey("enabled"))
        stripEnabled = doc["enabled"].as<bool>();

      if (doc.containsKey("r"))
        stripValues[0] = constrain(doc["r"].as<int>(), 0, 255);

      if (doc.containsKey("g"))
        stripValues[1] = constrain(doc["g"].as<int>(), 0, 255);

      if (doc.containsKey("b"))
        stripValues[2] = constrain(doc["b"].as<int>(), 0, 255);

      int r = stripEnabled ? (255 - stripValues[0]) : 255;
      int g = stripEnabled ? (255 - stripValues[1]) : 255;
      int b = stripEnabled ? (255 - stripValues[2]) : 255;

      ledcWrite(3, r);
      ledcWrite(4, g);
      ledcWrite(5, b);
    }
  }
};

// -------------------
// SETUP
// -------------------
void setup() {

  Serial.begin(115200);

  // RGB PWM
  for (int i = 0; i < 3; i++) {
    ledcSetup(i, 5000, 8);
    ledcAttachPin(rgbPins[i], i);
    ledcWrite(i, 255);
  }

  // STRIP PWM
  for (int i = 0; i < 3; i++) {
    ledcSetup(i + 3, 5000, 8);
    ledcAttachPin(stripPins[i], i + 3);
    ledcWrite(i + 3, 255);
  }

  // Реле
  for (int i = 0; i < 4; i++) {
    pinMode(relayPins[i], OUTPUT);
    digitalWrite(relayPins[i], LOW);
  }

  pinMode(LIGHT_SENSOR, INPUT);
  dht.begin();

  // BLE
  BLEDevice::init("SmartFarm_ESP32");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pDataCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_DATA,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pDataCharacteristic->addDescriptor(new BLE2902());

  pControlCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_CONTROL,
    BLECharacteristic::PROPERTY_WRITE
  );
  pControlCharacteristic->setCallbacks(new ControlCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
}

// -------------------
// LOOP
// -------------------
void loop() {

  if (deviceConnected) {

    float t = dht.readTemperature();
    float h = dht.readHumidity();

    if (isnan(t)) t = 0;
    if (isnan(h)) h = 0;

    int soilRaw1 = analogRead(SOIL1);
    int soilRaw2 = analogRead(SOIL2);
    int soilRaw3 = analogRead(SOIL3);
    int soilRaw4 = analogRead(SOIL4);
    int waterRaw = analogRead(WATER_SENSOR);
    int lightState = digitalRead(LIGHT_SENSOR);

    int soil1 = constrain(map(soilRaw1, SOIL_WET, SOIL_DRY, 100, 0), 0, 100);
    int soil2 = constrain(map(soilRaw2, SOIL_WET, SOIL_DRY, 100, 0), 0, 100);
    int soil3 = constrain(map(soilRaw3, SOIL_WET, SOIL_DRY, 100, 0), 0, 100);
    int soil4 = constrain(map(soilRaw4, SOIL_WET, SOIL_DRY, 100, 0), 0, 100);
    int waterLevel = constrain(map(waterRaw, 0, 4095, 0, 100), 0, 100);

    StaticJsonDocument<512> doc;

    doc["temperature"] = t;
    doc["humidity"] = h;
    doc["lightLevel"] = lightState == HIGH ? 0 : 100;
    doc["waterLevel"] = waterLevel;

    JsonArray soilMoisture1 = doc.createNestedArray("soilMoisture1");
    soilMoisture1.add(soil1);
    soilMoisture1.add(soil2);

    JsonArray soilMoisture2 = doc.createNestedArray("soilMoisture2");
    soilMoisture2.add(soil3);
    soilMoisture2.add(soil4);

    JsonArray relays = doc.createNestedArray("relays");
    for (int i = 0; i < 4; i++)
      relays.add(relayStates[i]);

    JsonObject rgb = doc.createNestedObject("rgbLights");
    rgb["enabled"] = rgbEnabled;
    rgb["r"] = rgbValues[0];
    rgb["g"] = rgbValues[1];
    rgb["b"] = rgbValues[2];

    JsonObject strip = doc.createNestedObject("stripLights");
    strip["enabled"] = stripEnabled;
    strip["r"] = stripValues[0];
    strip["g"] = stripValues[1];
    strip["b"] = stripValues[2];

    String output;
    serializeJson(doc, output);

    pDataCharacteristic->setValue(output.c_str());
    pDataCharacteristic->notify();
  }

  delay(1000);
}