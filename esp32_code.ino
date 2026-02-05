#include <BLEServer.h>
#include <BLE2902.h>

// UUID usluge i UUID vrijednosti karakteristika (isti kao i u mobilnoj aplikaciji)
#define SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_TX_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_RX_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

// GPIO nožice
#define PIN_LOCK    23 // zelena žica
#define PIN_UNLOCK  22 // smeđa žica
#define PIN_CHIME   32 // bijela žica

BLECharacteristic *pCharacteristicTX;
BLECharacteristic *pCharacteristicRX;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE: Device connected");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE: Device disconnected");
      
      pServer->startAdvertising();
      Serial.println("BLE: Advertising restarted");
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue();
      
      if (value.length() > 0) {
        Serial.print("BLE RX: ");
        Serial.println(value);
        
        // Uklanjanje bjelina
        value.trim();
        
        Serial.print("Command: '");
        Serial.print(value);
        Serial.println("'");
        
        // Upravljanje naredbama
        if (value == "HELLO") {
          Serial.println("HELLO received - connection working!");
        }
        else if (value == "CMD=LOCK" || value == "LOCK") {
          Serial.println("Executing LOCK command");
          digitalWrite(PIN_LOCK, HIGH);
          delay(300);
          digitalWrite(PIN_LOCK, LOW);
          Serial.println("LOCK executed - GPIO 23 triggered");
        }
        else if (value == "CMD=UNLOCK" || value == "UNLOCK") {
          Serial.println("Executing UNLOCK command");
          digitalWrite(PIN_UNLOCK, HIGH);
          delay(300);
          digitalWrite(PIN_UNLOCK, LOW);
          Serial.println("UNLOCK executed - GPIO 22 triggered");
        }
        else if (value == "CMD=CHIME" || value == "CHIME") {
          Serial.println("Executing CHIME command");
          digitalWrite(PIN_CHIME, HIGH);
          delay(333);
          digitalWrite(PIN_CHIME, LOW);
          Serial.println("CHIME executed - GPIO 32 triggered for 333ms");
        }
        else if (value == "MODE=PARK") {
          Serial.println("Mode set to PARK");
        }
        else if (value == "MODE=DRIVE") {
          Serial.println("Mode set to DRIVE");
        }
        else if (value.startsWith("SET=AUTOLOCK")) {
          // Parsiranje brzine za automatsko zaključavanje
          int speedIndex = value.indexOf("SPD=");
          if (speedIndex != -1) {
            String speedStr = value.substring(speedIndex + 4);
            int speedValue = speedStr.toInt();
            Serial.print("Auto-lock speed set to: ");
            Serial.println(speedValue);
          }
        }
        else if (value.startsWith("SET=CHIME")) {
          // Parsiranje brzine za aktivaciju zvonca
          int speedIndex = value.indexOf("SPD=");
          if (speedIndex != -1) {
            String speedStr = value.substring(speedIndex + 4);
            int speedValue = speedStr.toInt();
            Serial.print("Chime speed set to: ");
            Serial.println(speedValue);
          }
        }
        else {
          Serial.print("Unknown command: ");
          Serial.println(value);
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 BLE Car Controller Starting...");
  
  // Postavljanje GPIO nožica
  pinMode(PIN_LOCK, OUTPUT);
  pinMode(PIN_UNLOCK, OUTPUT);
  pinMode(PIN_CHIME, OUTPUT);
  
  // Inicijalizacija nožica u nisko stanje
  digitalWrite(PIN_LOCK, LOW);
  digitalWrite(PIN_UNLOCK, LOW);
  digitalWrite(PIN_CHIME, LOW);
  
  // Stvaranje BLE uređaja
  BLEDevice::init("ESP32-CarKey");
  
  // Stvaranje BLE poslužitelja
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // Stvaranje BLE usluge
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Stvaranje TX karakteristike
  pCharacteristicTX = pService->createCharacteristic(
                      CHARACTERISTIC_TX_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristicTX->addDescriptor(new BLE2902());
  
  // Stvaranje RX karakteristike
  pCharacteristicRX = pService->createCharacteristic(
                      CHARACTERISTIC_RX_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pCharacteristicRX->setCallbacks(new MyCallbacks());
  
  // Pokretanje usluge
  pService->start();
  
  // Pokretanje emitiranja
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  
  BLEDevice::startAdvertising();
  Serial.println("BLE: Advertising started. Waiting for connection...");
  Serial.println("Device name: ESP32-CarKey");
  Serial.print("Service UUID: ");
  Serial.println(SERVICE_UUID);
  Serial.print("RX Characteristic UUID: ");
  Serial.println(CHARACTERISTIC_RX_UUID);
}

void loop() {
  // Nepotrebno, sve je obrađeno unutar povratnih poziva BLE
  delay(1000);
}