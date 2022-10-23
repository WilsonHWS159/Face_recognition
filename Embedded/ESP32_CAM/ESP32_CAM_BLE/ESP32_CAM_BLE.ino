#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

#define CAMERA_MODEL_AI_THINKER

#include "esp_camera.h"
#include "camera_pins.h"


const char *Service_UUID = "180F";
const char *Characteristic[] = {"2A18", "2A19", "2A1A"};

camera_config_t config;
sensor_t *cam_ov2640 = NULL;

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
    Serial.println("BLE disconnect");
    BLEDevice::startAdvertising();
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

bool cam_init() {
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_UXGA;
  config.pixel_format = PIXFORMAT_JPEG; // for streaming
  //config.pixel_format = PIXFORMAT_RGB565; // for face detection/recognition
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  if (psramFound()) {
    config.jpeg_quality = 10;
    config.fb_count = 2;
    config.grab_mode = CAMERA_GRAB_LATEST;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.fb_location = CAMERA_FB_IN_DRAM;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera initial failed with error 0x%x!\n", err);
    return false;
  }
  cam_ov2640 = esp_camera_sensor_get();
  return true;
}

bool BLE_init() {
  BLEDevice::init("ESP32_CAM");
  pServer = BLEDevice::createServer();
  if (!pServer)
    return false;
  pServer->setCallbacks(new ESP32Cam_ServerCallbacks());
  pService = pServer->createService(Service_UUID);
  if (!pService)
    return false;
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
  return true;
}

void setup() {
  Serial.begin(115200);
  cam_init();
  BLE_init();
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
