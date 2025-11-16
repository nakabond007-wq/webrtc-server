import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_history.dart';

class CallHistoryService {
  static final CallHistoryService _instance = CallHistoryService._internal();
  factory CallHistoryService() => _instance;
  CallHistoryService._internal();

  static const String _historyKey = 'call_history';
  List<CallHistory> _history = [];

  List<CallHistory> get history => _history;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      _history = decoded.map((item) => CallHistory.fromJson(item)).toList();
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> addCall(CallHistory call) async {
    _history.insert(0, call);
    
    // Keep only last 50 calls
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }
    
    await _saveHistory();
  }

  Future<void> deleteCall(String callId) async {
    _history.removeWhere((call) => call.id == callId);
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = 
        _history.map((call) => call.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(encoded));
  }
}
