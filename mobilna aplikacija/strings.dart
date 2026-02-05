import 'language_service.dart';

class S {
  final AppLanguage lang;
  S(this.lang);

  bool get hr => lang == AppLanguage.hr;

  // SPAJANJE
  String get connectCar => hr ? "Poveži se s vozilom" : "Connect to Car";
  String get connected => hr ? "Povezano" : "Connected";

  // NASLOV APLIKACIJE
  String get appTitle => "CarKey";

  // NAVIGACIJA iliti NAČINI RADA
  String get homeScreen => hr ? "Početna stranica" : "Home Screen";
  String get parkingMode => hr ? "Način parkiranja" : "Parking Mode";
  String get drivingMode => hr ? "Način vožnje" : "Driving Mode";

  // PORUKE BLE USLUGE (sukladno porukama unutar ble_service.dart)
  String get bleConnectRequested => hr ? "BLE: Zahtjev za povezivanjem" : "BLE: connect requested";
  String get warningXiaomi => hr ? "UPOZORENJE: Xiaomi – pobrini se da je uređaj uparen" : "WARNING: Xiaomi – ensure device is paired";
  String bleStartingScan(String deviceName) => hr ? "BLE: Početak pretraživanja za $deviceName" : "BLE: Starting scan for $deviceName";
  String bleFoundDevice(String name, String id) => hr ? "BLE: Pronađen uređaj: $name ($id)" : "BLE: Found device: $name ($id)";
  String get successFoundEsp => hr ? "USPJEH: Pronađen ESP32-CarKey!" : "SUCCESS: Found ESP32-CarKey!";
  String get bleConnecting => hr ? "BLE: Povezivanje s uređajem..." : "BLE: Connecting to device...";
  String get successBleConnected => hr ? "USPJEH: BLE povezan s ESP32" : "SUCCESS: BLE connected to ESP32";
  String get warningBleDisconnected => hr ? "UPOZORENJE: BLE prekinut - pokušavam ponovno povezati..." : "WARNING: BLE disconnected - trying to reconnect...";
  String errorScan(String error) => hr ? "GREŠKA: Greška pretraživanja: $error" : "ERROR: Scan error: $error";
  String errorConnection(String error) => hr ? "GREŠKA: Greška povezivanja: $error" : "ERROR: Connection error: $error";
  String get bleDiscoveringServices => hr ? "BLE: Otkrivanje usluga..." : "BLE: Discovering services...";
  String bleFoundServices(int count) => hr ? "BLE: Pronađeno $count usluga" : "BLE: Found $count services";
  String bleService(String serviceStr) => hr ? "BLE: Usluga: $serviceStr" : "BLE: Service: $serviceStr";
  String get successFoundService => hr ? "USPJEH: Pronađena naša usluga!" : "SUCCESS: Found our service!";
  String bleCharacteristic(String charStr) => hr ? "BLE: Karakteristika: $charStr" : "BLE: Characteristic: $charStr";
  String get successFoundRxChar => hr ? "USPJEH: Pronađena RX karakteristika za pisanje!" : "SUCCESS: Found RX characteristic for writing!";
  String get errorServiceNotFound => hr ? "GREŠKA: Usluga nije pronađena! Dostupne usluge:" : "ERROR: Service not found! Available services:";
  String get errorRxCharNotFound => hr ? "GREŠKA: RX karakteristika nije pronađena!" : "ERROR: RX characteristic not found!";
  String errorServiceDiscovery(String e) => hr ? "GREŠKA: Otkrivanje usluga nije uspjelo: $e" : "ERROR: Service discovery failed: $e";
  String get errorCannotSendNotConnected => hr ? "GREŠKA: Ne mogu poslati - nisam povezan" : "ERROR: Cannot send - not connected";
  String get errorCannotSendRxNotFound => hr ? "GREŠKA: Ne mogu poslati - RX karakteristika nije pronađena" : "ERROR: Cannot send - RX characteristic not found";
  String bleSend(String msg) => hr ? "BLE SLANJE: '$msg'" : "BLE SEND: '$msg'";
  String successSent(String msg) => hr ? "USPJEH: Poslano '$msg'" : "SUCCESS: Sent '$msg'";
  String errorFailedToSend(String msg, String e) => hr ? "GREŠKA: Slanje '$msg' nije uspjelo: $e" : "ERROR: Failed to send '$msg': $e";
  String get debugTryingWriteWithoutResponse => hr ? "DEBUG: Pokušavam pisati bez odgovora..." : "DEBUG: Trying write without response...";
  String successSentWithoutResponse(String msg) => hr ? "USPJEH: Poslano '$msg' (bez odgovora)" : "SUCCESS: Sent '$msg' (without response)";
  String errorBothWriteMethodsFailed(String e) => hr ? "GREŠKA: Obje metode pisanja nisu uspjele: $e" : "ERROR: Both write methods failed: $e";
  String get bleDisconnected => hr ? "BLE: Prekinuto" : "BLE: Disconnected";

  // PORUKE PRILIKOM ULASKA U NAČINE RADA
  String get logParkingMode => hr ? "UX: Način parkiranja - ulaz" : "UX: Parking mode entered";
  String get logDrivingMode => hr ? "UX: Način vožnje - ulaz" : "UX: Driving mode entered";

  // PORUKE PRILIKOM OTKLJUČAVANJA/ZAKLJUČAVANJA
  String get logLockOk => hr ? "UX: Naredba ZAKLJUČAJ OK, sučelje ažurirano" : "UX: LOCK command OK, interface updated";
  String get logUnlockOk => hr ? "UX: Naredba OTKLJUČAJ OK, sučelje ažurirano" : "UX: UNLOCK command OK, interface updated";

  // PORUKE PRILIKOM AUTOMATSKOG ZAKLJUČAVANJA
  String logAutoLock(double speed) => hr ? "AUTO: Zaključano pri ${speed.toStringAsFixed(1)} km/h" : "AUTO: Locked at ${speed.toStringAsFixed(1)} km/h";
  String logAutoLockSet(double v) => hr ? "UX: Automatsko zaključavanje postavljeno na ${v.toInt()} km/h" : "UX: Auto-lock set to ${v.toInt()} km/h";

  // PORUKE PRILIKOM RADA ZVONCA
  String logChimeStart(double speed) => hr ? "ZVONCE: Aktivirano pri ${speed.toStringAsFixed(1)} km/h" : "CHIME: Activated at ${speed.toStringAsFixed(1)} km/h";
  String get logChimeStop => hr ? "ZVONCE: Isključeno" : "CHIME: Deactivated";
  String logChimeSet(double v) => hr ? "UX: Prag zvonca postavljen na ${v.toInt()} km/h" : "UX: Chime trigger set to ${v.toInt()} km/h";

  // PORUKE U NAČINU VOŽNJE
  String get currentSpeed => hr ? "Trenutna brzina" : "Current Speed";
  String get autoLockTrigger => hr ? "Automatsko zaključavanje" : "Auto-lock Trigger";
  String get chimeTrigger => hr ? "Zvonce" : "Chime Trigger";
}