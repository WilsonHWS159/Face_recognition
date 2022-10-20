#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

const char *Service_UUID = "180F";
const char *Characteristic[] = {"2A18", "2A19", "2A1A"};

BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pCharacteristic[3];
bool deviceConnected = false;

class ESP32Cam_ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
  }
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
  }
}

class ESP32Cam_Callbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string s = pCharacteristic->getValue();
    uint16_t len = s.length();
    if (len) {
      Serial.print("Received : ");
      for (uint16_t i = 0; i < len; i++)
        Serial.print(s[i]);
      Serial.println();
    }
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting BLE work!!!");

  BLEDevice::init("ESP32_CAM");
  pServer = BLEDevice::createServer();
  pService = pServer->createService(Service_UUID);
  pCharacteristic[0] = pService->createCharacteristic(Characteristic[0], 0x2);
  pCharacteristic[1] = pService->createCharacteristic(Characteristic[1], 0x7);
  pCharacteristic[2] = pService->createCharacteristic(Characteristic[2], 0x4);
  for (uint8_t i = 0; i < 3; i++)
    pCharacteristic[i]->setValue(Characteristic[i]);

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(Service_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Characteristic defined! Now you can read it in your phone!");
}

void loop() {
  delay(2000);
}
