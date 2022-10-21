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
};

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
  pServer->setCallbacks(new ESP32Cam_ServerCallbacks());
  pService = pServer->createService(Service_UUID);
  pCharacteristic[0] = pService->createCharacteristic(Characteristic[0], 0x2);
  pCharacteristic[1] = pService->createCharacteristic(Characteristic[1], 0x7);
  pCharacteristic[2] = pService->createCharacteristic(Characteristic[2], 0x4);
  pCharacteristic[0]->setCallbacks(new ESP32Cam_Callbacks());
  pCharacteristic[1]->setCallbacks(new ESP32Cam_Callbacks());
  pCharacteristic[1]->addDescriptor(new BLE2902());
  pCharacteristic[2]->addDescriptor(new BLE2902());
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
  if (deviceConnected) {
    pCharacteristic[1]->setValue("image test");
    pCharacteristic[1]->notify();
    Serial.println("test message sent");
    pCharacteristic[2]->setValue("2A1A test");
    pCharacteristic[2]->notify();
    for(;;)
      delay(1000);
  }
  //delay(2000);
}
