import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/ble_service.dart';
import 'services/car_state.dart';
import 'services/log_service.dart';
import 'services/language_service.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => LogService()),
        ChangeNotifierProxyProvider<LogService, BleService>(
          create: (context) => BleService(),
          update: (context, logService, bleService) {
            if (bleService == null) return BleService();
            bleService.logService = logService;
            return bleService;
          },
        ),
        ChangeNotifierProvider(create: (_) => CarState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CarKey',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: Colors.red[700],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}