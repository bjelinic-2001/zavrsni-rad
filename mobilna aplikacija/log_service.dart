import 'package:flutter/material.dart';

class LogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;

  LogEntry(this.tag, this.message) : timestamp = DateTime.now();
}

class LogService extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  static const int maxLines = 50;
  bool _showBleLogs = true;

  void addLog(String tag, String msg) {
    _logs.insert(0, LogEntry(tag, msg));
    if (_logs.length > maxLines) _logs.removeLast();
    notifyListeners();
  }

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void toggleBleLogs(bool show) {
    _showBleLogs = show;
    notifyListeners();
  }

  bool get showBleLogs => _showBleLogs;
}