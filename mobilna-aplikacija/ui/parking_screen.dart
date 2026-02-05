import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/car_state.dart';
import '../services/log_service.dart';
import '../services/language_service.dart';
import '../services/strings.dart';
import '../widgets/log_widget.dart';
import 'home_screen.dart' as home;
import 'driving_screen.dart' as driving;

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleService>();
      final log = context.read<LogService>();
      final s = S(context.read<LanguageService>().lang);

      ble.initWithContext(context);
      ble.send("MODE=PARK");
      log.addLog("UI", s.logParkingMode);
    });
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
        title: Text(s.parkingMode),
        actions: [
          TextButton(
            onPressed: lang.toggle,
            child: Text(
              lang.isHr ? "HR" : "EN",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_parking, size: 100),
                  const SizedBox(height: 8),
                  Text(
                    s.parkingMode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lang.isHr
                        ? "Zaključano: ${car.locked ? 'Da' : 'Ne'}"
                        : "Locked: ${car.locked ? 'Yes' : 'No'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: ElevatedButton(
                          onPressed: ble.connected && !car.locked
                              ? () {
                            car.updateLocked(true);
                            ble.send("CMD=LOCK");
                            log.addLog("UI", s.logLockOk);
                          }
                              : null,
                          child: const Icon(Icons.lock, size: 40),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: ElevatedButton(
                          onPressed: ble.connected && car.locked
                              ? () {
                            car.updateLocked(false);
                            ble.send("CMD=UNLOCK");
                            log.addLog("UI", s.logUnlockOk);
                          }
                              : null,
                          child: const Icon(Icons.lock_open, size: 40),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _nav(
                        context,
                        Icons.home,
                        s.homeScreen,
                        const home.HomeScreen(),
                      ),
                      _nav(
                        context,
                        Icons.directions_car,
                        s.drivingMode,
                        const driving.DrivingScreen(),
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

  Widget _nav(BuildContext context, IconData icon, String label, Widget screen) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            ),
            child: Icon(icon, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}