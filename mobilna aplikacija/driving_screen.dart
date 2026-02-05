import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/car_state.dart';
import '../services/log_service.dart';
import '../services/speed_service.dart';
import '../services/language_service.dart';
import '../services/strings.dart';
import '../widgets/log_widget.dart';
import 'home_screen.dart' as home;
import 'parking_screen.dart' as parking;

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});
  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  final SpeedService _speedService = SpeedService();

  double _currentSpeed = 0.0;
  bool _autoLocked = false;

  bool _chimeActive = false;
  bool _chimeLoopRunning = false;

  Timer? _autoLockDebounceTimer;
  Timer? _chimeDebounceTimer;

  DateTime _lastAutoLockChange = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastChimeChange = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleService>();
      final log = context.read<LogService>();
      final s = S(context.read<LanguageService>().lang);

      ble.initWithContext(context);
      ble.send("MODE=DRIVE");
      log.addLog("UI", s.logDrivingMode);
    });

    _startSpeedMonitoring();
  }

  void _startSpeedMonitoring() {
    _speedService.start();

    _speedService.speedStream.listen((speed) {
      setState(() => _currentSpeed = speed);

      final ble = context.read<BleService>();
      final car = context.read<CarState>();
      final log = context.read<LogService>();
      final s = S(context.read<LanguageService>().lang);

      /// Automatsko zaključavanje
      if (car.autoLockSpeed < 200 &&
          speed >= car.autoLockSpeed &&
          !_autoLocked &&
          DateTime.now().difference(_lastAutoLockChange) >
              const Duration(milliseconds: 500)) {
        if (!car.locked) {
          ble.send("CMD=LOCK");
          car.updateLocked(true);
          log.addLog("AUTO", s.logAutoLock(speed));
        }
        _autoLocked = true;
      }

      if (speed < 5.0) {
        _autoLocked = false;
      }

      /// Uvjet aktivacije zvonca
      final chimeCondition =
          car.chimeSpeed < 200 &&
              speed >= car.chimeSpeed &&
              DateTime.now().difference(_lastChimeChange) >
                  const Duration(milliseconds: 500);

      if (chimeCondition && !_chimeActive) {
        _chimeActive = true;
        log.addLog("CHIME", s.logChimeStart(speed));
        _runChimeLoop(ble);
      }

      if (!chimeCondition && _chimeActive) {
        _chimeActive = false;
        log.addLog("CHIME", s.logChimeStop);
      }
    });
  }

  Future<void> _runChimeLoop(BleService ble) async {
    if (_chimeLoopRunning) return;
    _chimeLoopRunning = true;

    while (_chimeActive) {
      ble.send("CMD=CHIME");
      await Future.delayed(const Duration(milliseconds: 333));
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    _chimeLoopRunning = false;
  }

  void _onAutoLockChanged(double value) {
    context.read<CarState>().updateAutoLockSpeed(value);
  }

  void _onAutoLockChangeEnd(double value) {
    _lastAutoLockChange = DateTime.now();
    _autoLockDebounceTimer?.cancel();

    _autoLockDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final ble = context.read<BleService>();
      final log = context.read<LogService>();
      final s = S(context.read<LanguageService>().lang);

      ble.send("SET=AUTOLOCK SPD=${value.toInt()}");
      log.addLog("UI", s.logAutoLockSet(value));
    });
  }

  void _onChimeChanged(double value) {
    context.read<CarState>().updateChimeSpeed(value);
  }

  void _onChimeChangeEnd(double value) {
    _lastChimeChange = DateTime.now();
    _chimeDebounceTimer?.cancel();

    _chimeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final ble = context.read<BleService>();
      final log = context.read<LogService>();
      final s = S(context.read<LanguageService>().lang);

      ble.send("SET=CHIME SPD=${value.toInt()}");
      log.addLog("UI", s.logChimeSet(value));
    });
  }

  @override
  void dispose() {
    _chimeActive = false;
    _autoLockDebounceTimer?.cancel();
    _chimeDebounceTimer?.cancel();
    _speedService.stop();
    _speedService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final car = context.watch<CarState>();
    final log = context.watch<LogService>();
    final lang = context.watch<LanguageService>();
    final s = S(lang.lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.drivingMode),
        actions: [
          TextButton(
            onPressed: lang.toggle,
            child: Text(
              lang.isHr ? "HR" : "EN",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// Prikaz brzine
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.red[50],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.currentSpeed,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_currentSpeed.toStringAsFixed(1)} km/h",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Upravljanje brzinama
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Icon(Icons.directions_car, size: 80),
                  const SizedBox(height: 6),
                  Text(
                    s.drivingMode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.autoLockTrigger,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: car.autoLockSpeed,
                            min: 0,
                            max: 200,
                            divisions: 40,
                            label: car.autoLockSpeed >= 200
                                ? "200 km/h"
                                : "${car.autoLockSpeed.toInt()} km/h",
                            activeColor: Colors.red,
                            onChanged:
                            ble.connected ? _onAutoLockChanged : null,
                            onChangeEnd:
                            ble.connected ? _onAutoLockChangeEnd : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.chimeTrigger,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: car.chimeSpeed,
                            min: 0,
                            max: 200,
                            divisions: 40,
                            label: car.chimeSpeed >= 200
                                ? "200 km/h"
                                : "${car.chimeSpeed.toInt()} km/h",
                            activeColor: Colors.orange,
                            onChanged:
                            ble.connected ? _onChimeChanged : null,
                            onChangeEnd:
                            ble.connected ? _onChimeChangeEnd : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navButton(
                        context,
                        Icons.home,
                        s.homeScreen,
                        const home.HomeScreen(),
                      ),
                      _navButton(
                        context,
                        Icons.local_parking,
                        s.parkingMode,
                        const parking.ParkingScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 150,
            child: LogWidget(
              logService: log,
              showOnHomeScreen: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(
      BuildContext context, IconData icon, String label, Widget screen) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            ),
            child: Icon(icon, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
