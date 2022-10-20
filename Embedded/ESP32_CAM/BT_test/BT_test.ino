#include<esp_bt_device.h>
#include<BLEDevice.h>
#include<BLEUtils.h>
#include<BLEServer.h>
#include<BLE2902.h>

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

static BLEService *pService;
static BLECharacteristic *CountCharacteristic;

uint32_t number;

bool bleConnected = false;

class ServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    bleConnected = true;
  };
  
  void onDisconnect(BLEServer *pServer)
  { 
    // 斷線回呼
    bleConnected = false;
    Serial.println("連線中斷");
    BLEDevice::startAdvertising(); // 重新發出廣告
  }
};

void printDeviceAddress() {
  const uint8_t* point = esp_bt_dev_get_address();
  for (int i = 0; i < 6; i++) {
    char str[3];
    sprintf(str, "%02X", (int)point[i]);
    Serial.print(str);
 
    if (i < 5){
      Serial.print(":");
    }
  }
}


void setup() {
  Serial.begin(115200);
  Serial.println("開始啟動BLE裝置!");

  BLEDevice::init("ESP32 Server_dev");//BLE裝置名稱
  BLEServer *pServer = BLEDevice::createServer();//初始化、並啟動BLE Server功能
  pServer->setCallbacks(new ServerCallbacks()); //設置伺服器回調函式為ServerCallbacks
  pService = pServer->createService(SERVICE_UUID);//BLE Server 啟動服務並設置指定UUID
  CountCharacteristic = pService->createCharacteristic(         //BLE 服務的每筆資料稱特徵Characteristic，設置其中的"UUID"、"屬性"
                         CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_NOTIFY
                       );
  
          
  CountCharacteristic->addDescriptor(new BLE2902()); // 新增描述
  

  BLEDescriptor *pDesc = new BLEDescriptor((uint16_t)0x2901);
  pDesc->setValue("數值計數");//描述內容
  CountCharacteristic->addDescriptor(pDesc);//對特徵增加描述內容
  // 啟動服務
  pService->start();
  //開始對外廣播BLE SERVER
  pServer->getAdvertising()->start();
  //設置廣播內容
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  // 開始對外廣播
  BLEDevice::startAdvertising();
  Serial.println("等待用戶端連線…");
  printDeviceAddress();
  number = 0;
}

void loop() {
  float ng = analogRead(34);
  
  if(bleConnected){
    
      if(ng>0){
        String ng_str = String(ng);
        String data_send = String(number);
        Serial.printf("發送:%s\n",ng_str);
        CountCharacteristic->setValue(data_send.c_str());
        CountCharacteristic->notify();
        number++;
      }
    }
  else{
    number = 0;
  }
    
    delay(2000);
}
