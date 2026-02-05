import 'package:flutter/material.dart';
import '../services/log_service.dart';

class LogWidget extends StatefulWidget {
  final LogService logService;
  final bool showOnHomeScreen;

  const LogWidget({
    super.key,
    required this.logService,
    this.showOnHomeScreen = false,
  });

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.logService.addListener(_onNewLog);
  }

  @override
  void dispose() {
    widget.logService.removeListener(_onNewLog);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewLog() {
    // Uvijek prikazuj najnoviju poruku
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prikazuj poruke ovisno o tome jesmo li na početnoj stranici
    final filteredLogs = widget.showOnHomeScreen
        ? widget.logService.logs
        : widget.logService.logs.where((log) => log.tag != "BLE").toList();

    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.grey[50],
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final entry = filteredLogs[index];

          Color color = Colors.black;
          switch (entry.tag) {
            case "BLE":
              color = Colors.blue;
              break;
            case "ERROR":
              color = Colors.red;
              break;
            case "WARNING":
              color = Colors.orange;
              break;
            case "SUCCESS":
              color = Colors.green;
              break;
            case "UX":
              color = Colors.purple;
              break;
            case "UI":
              color = Colors.teal;
              break;
            case "DEBUG":
              color = Colors.grey;
              break;
            case "AUTO":
              color = Colors.deepOrange;
              break;
            case "CHIME":
              color = Colors.orange;
              break;
            case "TEST":
              color = Colors.purpleAccent;
              break;
            default:
              color = Colors.black;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              "${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')} ${entry.message}",
              style: TextStyle(fontSize: 12, color: color),
            ),
          );
        },
      ),
    );
  }
}