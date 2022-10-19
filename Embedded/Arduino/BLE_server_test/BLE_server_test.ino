#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

const char *Service_UUID = "180F";
const char *Characteristic[] = {"2A18", "2A19", "2A1A"};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting BLE work!!!");

  BLEDevice::init("ESP32_CAM");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(Service_UUID);
  BLECharacteristic *pCharacteristic[3];
  pCharacteristic[0] = pService->createCharacteristic(Characteristic[0], 0x2);
  pCharacteristic[1] = pService->createCharacteristic(Characteristic[1], 0x7);
  pCharacteristic[2] = pService->createCharacteristic(Characteristic[2], 0x4);
  for (char i = 0; i < 3; i++)
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
  // put your main code here, to run repeatedly:
  delay(2000);
}
