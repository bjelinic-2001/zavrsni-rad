import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/log_service.dart';
import '../services/language_service.dart';
import '../services/strings.dart';
import '../widgets/log_widget.dart';
import 'parking_screen.dart' as parking;
import 'driving_screen.dart' as driving;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final lang = context.watch<LanguageService>();
    final logService = context.watch<LogService>();
    final s = S(lang.lang);

    ble.initWithContext(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          TextButton(
            onPressed: lang.toggle,
            child: Text(
              lang.isHr ? "HR" : "EN",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                  Text(
                    lang.isHr
                        ? "Povezano: ${ble.connected ? 'Da' : 'Ne'}"
                        : "Status: ${ble.connected ? 'Connected' : 'Disconnected'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: ble.connected ? null : () => ble.connect(),
                    child: Text(
                      ble.connected ? s.connected : s.connectCar,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _nav(
                        context,
                        Icons.local_parking,
                        s.parkingMode,
                        const parking.ParkingScreen(),
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

          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "Završni rad [meh]\n"
                  "Autor: Borna Jelinić\n"
                  "JMBAG: 0246093745\n"
                  "2026 © TVZ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),

          SizedBox(
            height: 150,
            child: LogWidget(
              logService: logService,
              showOnHomeScreen: true,
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