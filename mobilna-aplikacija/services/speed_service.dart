import 'dart:async';
import 'package:geolocator/geolocator.dart';

class SpeedService {
  final _ctrl = StreamController<double>.broadcast();
  Stream<double> get speedStream => _ctrl.stream;

  StreamSubscription<Position>? _sub;

  Future<void> start() async {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception('Location permission not granted');
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      final speedKmh = (pos.speed * 3.6).clamp(0, 300).toDouble();
      _ctrl.add(speedKmh);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _ctrl.close();
  }
}