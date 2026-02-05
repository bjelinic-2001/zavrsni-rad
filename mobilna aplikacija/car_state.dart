import 'package:flutter/material.dart';

class CarState extends ChangeNotifier {
  bool locked = true;
  double autoLockSpeed = 200.0;
  double chimeSpeed = 200.0;

  void updateLocked(bool isLocked) {
    locked = isLocked;
    notifyListeners();
  }

  void updateAutoLockSpeed(double speed) {
    autoLockSpeed = speed;
    notifyListeners();
  }

  void updateChimeSpeed(double speed) {
    chimeSpeed = speed;
    notifyListeners();
  }
}